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
final class MapController: ObservableObject {

    @Published var markers: [IdentifiablePlace] = []
    @Published var region: MKCoordinateRegion

    private let geocoder = CLGeocoder()
    private let geocodeQueue = DispatchQueue(label: "map.geocode.serial")

    private var coordinateCache: [String: CLLocationCoordinate2D] = [:]
    private var hasHydrated = false   // 🔑 prevents re-clearing

    init(region: MKCoordinateRegion) {
        self.region = region
    }

    // MARK: - Bulk Load (Startup / Tab Return)

    func hydrateMarkers(prospects: [Prospect], customers: [Customer]) {
        markers.removeAll()

        let items =
            prospects.map { ($0.address, $0.knockCount, "Prospects") } +
            customers.map { ($0.address, $0.knockCount, "Customers") }

        let group = DispatchGroup()
        var temp: [IdentifiablePlace] = []

        for (address, count, list) in items {
            let key = normalize(address)

            if let cached = coordinateCache[key] {
                temp.append(.init(address: address, location: cached, count: count, list: list))
                continue
            }

            group.enter()
            geocodeQueue.async {
                self.geocoder.geocodeAddressString(address) { placemarks, _ in
                    defer { group.leave() }
                    guard let coord = placemarks?.first?.location?.coordinate else { return }
                    self.coordinateCache[key] = coord
                    temp.append(.init(address: address, location: coord, count: count, list: list))
                }
            }
        }

        group.notify(queue: .main) {
            self.markers = temp
            self.recenterToFitAllMarkers()
        }
    }

    // MARK: - Incremental Add (Performance Path)

    func addMarker(address: String, count: Int = 0, list: String = "Prospects") {
        let key = normalize(address)

        if let cached = coordinateCache[key] {
            appendIfMissing(address, cached, count, list)
            return
        }

        geocodeQueue.async {
            self.geocoder.geocodeAddressString(address) { placemarks, _ in
                guard let coord = placemarks?.first?.location?.coordinate else { return }
                self.coordinateCache[key] = coord

                DispatchQueue.main.async {
                    self.appendIfMissing(address, coord, count, list)
                }
            }
        }
    }

    private func appendIfMissing(
        _ address: String,
        _ coord: CLLocationCoordinate2D,
        _ count: Int,
        _ list: String
    ) {
        guard !markers.contains(where: { normalize($0.address) == normalize(address) }) else { return }

        markers.append(
            IdentifiablePlace(address: address, location: coord, count: count, list: list)
        )
    }

    // MARK: - Region

    func recenterToFitAllMarkers() {
        guard !markers.isEmpty else { return }

        let lats = markers.map { $0.location.latitude }
        let lons = markers.map { $0.location.longitude }

        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.4, 0.01),
            longitudeDelta: max((lons.max()! - lons.min()!) * 1.4, 0.01)
        )

        region = MKCoordinateRegion(
            center: .init(
                latitude: (lats.min()! + lats.max()!) / 2,
                longitude: (lons.min()! + lons.max()!) / 2
            ),
            span: span
        )
    }

    private func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
