//
//  MapController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation
import MapKit
import CoreLocation
import Contacts

/// `MapController` manages map-related logic such as marker placement, geocoding searches,
/// and updating the visible map region based on annotations.
///
/// This class supports:
/// - Managing a list of `IdentifiablePlace` markers
/// - Performing geocoded address searches
/// - Centering and zooming the map to fit all markers
/// - Dynamically updating markers based on prospects
@MainActor
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
            
            let unitCount = unitsDict.keys.count
            
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

        Task { [weak self] in
            guard let self = self else { return }
            guard let coordinate = await self.geocodedCoordinate(for: query) else { return }

            if let existingIndex = self.markers.firstIndex(where: { self.normalized($0.address) == key }) {
                self.markers[existingIndex].count += 1
            } else {
                let newPlace = IdentifiablePlace(
                    address: query,
                    location: coordinate,
                    count: 1
                )
                self.markers.append(newPlace)
            }
            // self.updateRegionToFitAllMarkers()
        }
    }
    
    func recenterToFitAllMarkers() {
        updateRegionToFitAllMarkers()
    }

    func centerMapOnUserLocation(_ coordinate: CLLocationCoordinate2D) {
        moveMap(
            to: coordinate,
            latitudinalMeters: 650,
            longitudinalMeters: 650
        )
    }

    func moveMap(
        to coordinate: CLLocationCoordinate2D,
        latitudinalMeters: CLLocationDistance,
        longitudinalMeters: CLLocationDistance
    ) {
        moveMap(
            to: MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: latitudinalMeters,
                longitudinalMeters: longitudinalMeters
            )
        )
    }

    func moveMap(to targetRegion: MKCoordinateRegion) {
        guard !regionsMatch(region, targetRegion) else { return }
        region = targetRegion
    }

    private func regionsMatch(_ lhs: MKCoordinateRegion, _ rhs: MKCoordinateRegion) -> Bool {
        abs(lhs.center.latitude - rhs.center.latitude) <= 0.0001 &&
        abs(lhs.center.longitude - rhs.center.longitude) <= 0.0001 &&
        abs(lhs.span.latitudeDelta - rhs.span.latitudeDelta) <= 0.0001 &&
        abs(lhs.span.longitudeDelta - rhs.span.longitudeDelta) <= 0.0001
    }

    private func offsetRegion(
        for coordinate: CLLocationCoordinate2D,
        latitudinalMeters: CLLocationDistance,
        longitudinalMeters: CLLocationDistance,
        targetYRatio: CGFloat
    ) -> MKCoordinateRegion {
        let baseRegion = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: latitudinalMeters,
            longitudinalMeters: longitudinalMeters
        )
        let clampedYRatio = max(0, min(1, targetYRatio))
        let latitudeOffset = baseRegion.span.latitudeDelta * (0.5 - clampedYRatio)
        let adjustedCenter = CLLocationCoordinate2D(
            latitude: coordinate.latitude - latitudeOffset,
            longitude: coordinate.longitude
        )

        return MKCoordinateRegion(center: adjustedCenter, span: baseRegion.span)
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
        Task { [weak self] in
            guard let self = self else { return }
            guard let coordinate = await self.geocodedCoordinate(for: address) else { return }

            let newPlace = IdentifiablePlace(
                address: address,
                location: coordinate,
                count: count,
                list: list
            )
            self.markers.append(newPlace)
            // self.updateRegionToFitAllMarkers()
        }
    }
    
    @MainActor
    func centerMapForPopup(coordinate: CLLocationCoordinate2D) {
        moveMap(
            to: offsetRegion(
                for: coordinate,
                latitudinalMeters: 250,
                longitudinalMeters: 250,
                targetYRatio: 0.25
            )
        )
    }

    func centerMapForSelectedPopup(
        coordinate: CLLocationCoordinate2D,
        bottomSheetFraction: CGFloat,
        targetVisibleYRatio: CGFloat = 0.5
    ) {
        let visibleYRatio = max(0, min(1, (1 - bottomSheetFraction) * targetVisibleYRatio))
        moveMap(
            to: offsetRegion(
                for: coordinate,
                latitudinalMeters: 250,
                longitudinalMeters: 250,
                targetYRatio: visibleYRatio
            )
        )
    }
    
    func centerMapForNewProperty(coordinate: CLLocationCoordinate2D) {
        let mapHeight = MapDisplayView.cachedMapView?.bounds.height ?? 0
        let visibleHeight = mapHeight > 0 ? max(mapHeight - 250, 1) : 1
        let targetYRatio = mapHeight > 0 ? (visibleHeight / 2) / mapHeight : 0.5

        moveMap(
            to: offsetRegion(
                for: coordinate,
                latitudinalMeters: 180,
                longitudinalMeters: 180,
                targetYRatio: targetYRatio
            )
        )
    }
    
    func reverseGeocode(
        coordinate: CLLocationCoordinate2D
    ) async -> String? {

        let location = CLLocation(
            latitude: coordinate.latitude,
           longitude: coordinate.longitude
        )

        do {
            if #available(iOS 26.0, *) {
                guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
                let mapItems = try await request.mapItems
                guard let mapItem = mapItems.first else { return nil }

                return mapItem.addressRepresentations?.fullAddress(
                    includingRegion: false,
                    singleLine: true
                ) ?? mapItem.address?.fullAddress ?? mapItem.name
            } else {
                let placemark = try await CLGeocoder().reverseGeocodeLocation(location).first
                guard let placemark else { return nil }
                return formattedAddress(from: placemark)
            }
        } catch {
            print("❌ Reverse geocode failed:", error)
            return nil
        }
    }

    private func geocodedCoordinate(for address: String) async -> CLLocationCoordinate2D? {
        if #available(iOS 26.0, *) {
            guard let request = MKGeocodingRequest(addressString: address) else { return nil }

            do {
                let mapItems = try await request.mapItems
                return mapItems.first?.location.coordinate
            } catch {
                return nil
            }
        } else {
            do {
                return try await CLGeocoder()
                    .geocodeAddressString(address)
                    .first?
                    .location?
                    .coordinate
            } catch {
                return nil
            }
        }
    }

    private func formattedAddress(from placemark: CLPlacemark) -> String? {
        if let postal = placemark.postalAddress {
            return CNPostalAddressFormatter()
                .string(from: postal)
                .replacingOccurrences(of: "\n", with: ", ")
        }

        if let name = placemark.name,
           let street = placemark.thoroughfare {
            return "\(name) \(street)"
        }

        let parts = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ]

        let address = parts
            .compactMap { $0 }
            .joined(separator: " ")

        return address.isEmpty ? nil : address
    }
    
    /// Snaps a given coordinate to the nearest road using a short MKDirections route.
    /// - Parameter coordinate: The coordinate to snap.
    /// - Returns: The coordinate snapped to the nearest road, or the original if snapping fails.
    func snapToNearestRoad(coordinate: CLLocationCoordinate2D) async -> CLLocationCoordinate2D {

        let request = MKDirections.Request()

        // Tiny offset destination (~10m) to force route solving
        let offset = 0.00009

        request.source = mapItem(for: coordinate)

        request.destination = mapItem(
            for: CLLocationCoordinate2D(
                latitude: coordinate.latitude + offset,
                longitude: coordinate.longitude + offset
            )
        )

        request.transportType = .walking
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()

            // First polyline point = snapped road position
            if let route = response.routes.first {
                let points = route.polyline.points()
                if route.polyline.pointCount > 0 {
                    return points[0].coordinate
                }
            }
        } catch {
            print("❌ Road snap failed:", error)
        }

        // Fallback: original coordinate
        return coordinate
    }

    private func mapItem(for coordinate: CLLocationCoordinate2D) -> MKMapItem {
        if #available(iOS 26.0, *) {
            return MKMapItem(
                location: CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                ),
                address: nil
            )
        } else {
            return MKMapItem(
                placemark: MKPlacemark(coordinate: coordinate)
            )
        }
    }
    
}

extension MapController {
    func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
        await geocodedCoordinate(for: address)
    }
}
