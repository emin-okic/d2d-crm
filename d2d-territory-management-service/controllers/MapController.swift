//
//  MapController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation
import MapKit
import CoreLocation

/// `MapController` manages map-related logic such as marker placement, geocoding searches,
/// and updating the visible map region based on annotations.
///
/// This class supports:
/// - Managing a list of `IdentifiablePlace` markers
/// - Performing geocoded address searches
/// - Centering and zooming the map to fit all markers
/// - Dynamically updating markers based on prospects
class MapController: ObservableObject {
    
    /// Published list of markers (used in SwiftUI map annotations)
    @Published var markers: [IdentifiablePlace] = []

    /// Current visible region of the map
    @Published var region: MKCoordinateRegion
    
    /// Initializes the controller with a given map region.
    init(region: MKCoordinateRegion) {
        self.region = region
    }
    
    /// Replaces existing markers with those derived from the provided list of prospects.
    /// - Parameter prospects: Array of `Prospect` objects to display.
    func setMarkers(prospects: [Prospect], customers: [Customer]) {
        
        clearMarkers()
        
        var groups: [String: AddressGroup] = [:]
        
        for p in prospects {
            let parsed = parseAddress(p.address)
            groups[parsed.base, default: AddressGroup(base: parsed.base, units: [:])]
                .units[parsed.unit, default: []]
                .append(.prospect(p))
        }
        
        for c in customers {
            let parsed = parseAddress(c.address)
            groups[parsed.base, default: AddressGroup(base: parsed.base, units: [:])]
                .units[parsed.unit, default: []]
                .append(.customer(c))
        }
        
        for (_, group) in groups {
            let base = group.base
            let unitsDict = group.units
            
            // Pick any contact to get a coordinate
            guard let firstContact = unitsDict.values.first?.first,
                  let coord = firstContact.coordinate else { continue }
            
            // ---- Step 2: Decide marker type ----
            let contactCount = unitsDict.values.reduce(0) { $0 + $1.count }
            
            let unitKeys = unitsDict.keys.compactMap { $0 }
            
            let unitCount = Set(unitKeys).count
            
            let isMultiUnit = unitCount > 1
            
            let showsMultiContact = (!isMultiUnit && contactCount > 1)
            
            let hasCustomer = unitsDict.values.flatMap { $0 }.contains { $0.isCustomer }
            let hasUnqualified = unitsDict.values.flatMap { $0 }.contains { $0.isUnqualified }
            
            let list = hasCustomer ? "Customers" : "Prospects"
            let isUnqualified = !hasCustomer && hasUnqualified
            
            let totalKnocks = unitsDict.values
                .flatMap { $0 }
                .reduce(0) { $0 + $1.knockCount }
            
            markers.append(
                IdentifiablePlace(
                    address: base,
                    location: coord,
                    count: totalKnocks,
                    unitCount: unitCount,
                    contactCount: contactCount,
                    list: list,
                    isUnqualified: isUnqualified,
                    isMultiUnit: isMultiUnit,
                    showsMultiContact: showsMultiContact
                )
            )
        }
    }
    
    /// Clears all existing markers from the map.
    func clearMarkers() {
        markers.removeAll()
    }

    /// Normalizes a string (e.g. address) for comparison (lowercased and trimmed).
    private func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    /// Performs a geocoding search on the provided address and places or updates a marker on the map.
    /// - Parameter query: The address string to geocode.
    func performSearch(query: String) {
        let key = normalized(query)
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(query) { [weak self] placemarks, error in
            guard let self = self else { return }
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                return
            }
            
            DispatchQueue.main.async {
                if let existingIndex = self.markers.firstIndex(where: { self.normalized($0.address) == key }) {
                    self.markers[existingIndex].count += 1
                } else {
                    let newPlace = IdentifiablePlace(
                        address: query,
                        location: location.coordinate,
                        count: 1
                    )
                    self.markers.append(newPlace)
                }
                // self.updateRegionToFitAllMarkers()
            }
        }
    }
    
    func recenterToFitAllMarkers() {
            updateRegionToFitAllMarkers()
        }
    
    /// Updates the `region` property to fit all current markers on the map.
    private func updateRegionToFitAllMarkers() {
        guard !markers.isEmpty else { return }

        let latitudes = markers.map { $0.location.latitude }
        let longitudes = markers.map { $0.location.longitude }

        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let latDelta = (maxLat - minLat) * 1.5
        let lonDelta = (maxLon - minLon) * 1.5

        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.01),
                                   longitudeDelta: max(lonDelta, 0.01))
        )
    }
    
    /// Geocodes and adds map markers for the given list of prospects.
    /// - Parameter prospects: Array of `Prospect` objects.
    func addProspects(_ prospects: [Prospect]) {
        for prospect in prospects {
            performSearch(query: prospect.address)
        }
    }
    
    /// This is removable now
    private func geocodeAndAdd(address: String, count: Int, list: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
            guard let self = self else { return }
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                return
            }

            DispatchQueue.main.async {
                let newPlace = IdentifiablePlace(
                    address: address,
                    location: location.coordinate,
                    count: count,
                    list: list
                )
                self.markers.append(newPlace)
                // self.updateRegionToFitAllMarkers()
            }
        }
    }
    
    @MainActor
    func centerMapForPopup(coordinate: CLLocationCoordinate2D) {

        // Target zoom (tight enough to matter visually)
        let latMeters: CLLocationDistance = 250
        let lonMeters: CLLocationDistance = 250

        // Convert meters → degrees (approx)
        let metersToDegrees = 1.0 / 111_000.0
        let latitudeSpanDegrees = latMeters * metersToDegrees

        // Push marker into TOP HALF (25% from top)
        let verticalOffset = latitudeSpanDegrees * 0.25

        let adjustedCenter = CLLocationCoordinate2D(
            latitude: coordinate.latitude - verticalOffset,
            longitude: coordinate.longitude
        )

        self.region = MKCoordinateRegion(
            center: adjustedCenter,
            latitudinalMeters: latMeters,
            longitudinalMeters: lonMeters
        )
        
    }
    
    func centerMapForNewProperty(coordinate: CLLocationCoordinate2D) {
        guard let mapView = MapDisplayView.cachedMapView else { return }

        // Convert map coordinate → screen point
        let point = mapView.convert(coordinate, toPointTo: mapView)

        // Visible height minus detented sheet (~260)
        let sheetHeight: CGFloat = 260
        let visibleHeight = mapView.bounds.height - sheetHeight

        // Target Y = vertical center of visible map area
        let targetY = visibleHeight / 2

        // Calculate vertical delta in screen space
        let deltaY = point.y - targetY

        // Convert that delta back into map coordinates
        let offsetPoint = CGPoint(
            x: point.x,
            y: point.y + deltaY
        )

        let offsetCoordinate = mapView.convert(offsetPoint, toCoordinateFrom: mapView)

        let region = MKCoordinateRegion(
            center: offsetCoordinate,
            span: mapView.region.span
        )

        mapView.setRegion(region, animated: true)
    }
    
}

extension MapController {
    func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
        return await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let coordinate = placemarks?.first?.location?.coordinate {
                    continuation.resume(returning: coordinate)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
