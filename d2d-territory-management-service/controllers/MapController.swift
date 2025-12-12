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
@MainActor
class MapController: ObservableObject {
    
    /// Published list of markers (used in SwiftUI map annotations)
    @Published var markers: [IdentifiablePlace] = []

    /// Current visible region of the map
    @Published var region: MKCoordinateRegion
    
    /// Geocode Helpers
    private let geocodeQueue = DispatchQueue(label: "com.d2d.geocode.serial")
    private var cache: [String: CLLocationCoordinate2D] = [:]
    private let geocoder = CLGeocoder()
    
    /// Initializes the controller with a given map region.
    init(region: MKCoordinateRegion) {
        self.region = region
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

        // 1. Cache hit → instant placement
        if let coord = cache[key] {
            DispatchQueue.main.async {
                if let idx = self.markers.firstIndex(where: { self.normalized($0.address) == key }) {
                    self.markers[idx].count += 1
                } else {
                    self.markers.append(
                        IdentifiablePlace(address: query,
                                          location: coord,
                                          count: 1)
                    )
                }
            }
            return
        }

        // 2. Throttled geocode → serial queue
        geocodeQueue.async {
            self.geocoder.geocodeAddressString(query) { [weak self] placemarks, _ in
                guard let self else { return }
                guard let loc = placemarks?.first?.location else { return }

                let coord = loc.coordinate
                self.cache[key] = coord

                DispatchQueue.main.async {
                    if let idx = self.markers.firstIndex(where: { self.normalized($0.address) == key }) {
                        self.markers[idx].count += 1
                    } else {
                        self.markers.append(
                            IdentifiablePlace(address: query,
                                              location: coord,
                                              count: 1)
                        )
                    }
                }
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
    
    /// Replaces existing markers with those derived from the provided list of prospects.
    /// - Parameter prospects: Array of `Prospect` objects to display.

    func setMarkers(prospects: [Prospect], customers: [Customer]) {
        let items: [(String, Int, String)] =
            prospects.map { ($0.address, $0.knockCount, "Prospects") } +
            customers.map { ($0.address, $0.knockCount, "Customers") }

        var temp: [IdentifiablePlace] = []
        let group = DispatchGroup()

        for (address, count, list) in items {
            let key = normalized(address)

            // Cache hit: immediate append
            if let coord = cache[key] {
                temp.append(
                    IdentifiablePlace(address: address,
                                      location: coord,
                                      count: count,
                                      list: list)
                )
                continue
            }

            // No cache → throttle geocode
            group.enter()
            geocodeQueue.async {
                self.geocoder.geocodeAddressString(address) { [weak self] placemarks, _ in
                    guard let self else { group.leave(); return }
                    defer { group.leave() }

                    guard let loc = placemarks?.first?.location else { return }
                    let coord = loc.coordinate
                    self.cache[key] = coord

                    temp.append(
                        IdentifiablePlace(address: address,
                                          location: coord,
                                          count: count,
                                          list: list)
                    )
                }
            }
        }

        // Atomic update when all geocodes finish
        group.notify(queue: .main) {
            self.markers = temp
        }
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
