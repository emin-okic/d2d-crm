//
//  SearchBarController.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import Foundation
@preconcurrency import MapKit
import CoreLocation
import Contacts

enum SearchBarController {
    private struct NearbyPropertyCandidate {
        let item: MKMapItem
        let distance: CLLocationDistance
        let hasStreetNumber: Bool
        let isResidential: Bool
        let isNearby: Bool

        var rank: Int {
            if isResidential && isNearby { return 0 }
            if hasStreetNumber && isNearby { return 1 }
            if isNearby { return 2 }
            if isResidential { return 3 }
            if hasStreetNumber { return 4 }
            return 5
        }
    }

    /// Resolves a selected search completion to a general address string (e.g., map title).
    @MainActor
    static func resolveAddress(from completion: MKLocalSearchCompletion) async -> String? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            return response.mapItems.first.map { displayAddress(for: $0, fallback: completion.title) } ?? completion.title
        } catch {
            print("❌ Error resolving address: \(error.localizedDescription)")
            return nil
        }
    }
    
    @MainActor
    static func resolveFreeformSearch(
        query: String
    ) async -> MKMapItem? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.resultTypes = .address

        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.first
        } catch {
            print("❌ Freeform search failed:", error.localizedDescription)
            return nil
        }
    }
    
    @MainActor
    static func resolveAndSelectAddress(
        from completion: MKLocalSearchCompletion,
        onResolved: @escaping (String) -> Void
    ) {
        Task { @MainActor in
            guard let selectedAddress = await resolveAddress(from: completion) else { return }
            onResolved(selectedAddress)
        }
    }

    static func nearbyHomeSearchResults(
        near coordinate: CLLocationCoordinate2D,
        limit: Int = 5
    ) async -> [MKMapItem] {
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let maximumDistance: CLLocationDistance = 650
        var uniqueItems: [String: NearbyPropertyCandidate] = [:]

        func addCandidate(_ item: MKMapItem, fallback: String) {
            let distance = item.location.distance(from: origin)
            guard distance >= 2 else { return }

            let address = displayAddress(for: item, fallback: fallback)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !address.isEmpty else { return }

            let startsWithStreetNumber = address.range(
                of: #"^\d+[A-Za-z]?(?:-\d+)?\s+"#,
                options: .regularExpression
            ) != nil

            let key = address
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .replacingOccurrences(of: ",", with: "")
            let candidate = NearbyPropertyCandidate(
                item: item,
                distance: distance,
                hasStreetNumber: startsWithStreetNumber,
                isResidential: startsWithStreetNumber && item.pointOfInterestCategory == nil,
                isNearby: distance <= maximumDistance
            )

            if let existing = uniqueItems[key],
               (existing.rank < candidate.rank
                || (existing.rank == candidate.rank && existing.distance <= distance)) {
                return
            }
            uniqueItems[key] = candidate
        }

        func hasEnoughNearbyHomes() -> Bool {
            uniqueItems.values.filter { $0.rank == 0 }.count >= limit
        }

        // Local Search is optimized for places and businesses. Sample the nearby blocks
        // directly so reverse geocoding can surface ordinary street addresses as well.
        for probeRing in nearbyProbeRings(around: coordinate) {
            let ringItems = await withTaskGroup(of: [MKMapItem].self) { group in
                for probeCoordinate in probeRing {
                    group.addTask {
                        let location = CLLocation(
                            latitude: probeCoordinate.latitude,
                            longitude: probeCoordinate.longitude
                        )
                        guard let request = MKReverseGeocodingRequest(location: location) else {
                            return []
                        }
                        return (try? await request.mapItems) ?? []
                    }
                }

                var items: [MKMapItem] = []
                for await result in group {
                    items += result
                }
                return items
            }

            for item in ringItems {
                addCandidate(item, fallback: "Nearby home")
            }

            // Finish each ring so every direction is represented before stopping.
            if hasEnoughNearbyHomes() { break }
        }

        // Keep address search as a fallback, but don't allow MapKit's regional bias to
        // admit distant results or named points of interest.
        let searchRegion = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: maximumDistance * 2,
            longitudinalMeters: maximumDistance * 2
        )
        let queries = ["residential address", "house", "home", "address"]

        for query in queries where !hasEnoughNearbyHomes() {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = .address
            request.region = searchRegion

            do {
                let response = try await MKLocalSearch(request: request).start()
                for item in response.mapItems {
                    addCandidate(item, fallback: item.name ?? query)
                }
            } catch {
                print("❌ Nearby home search failed:", error.localizedDescription)
            }
        }

        return uniqueItems.values
            .sorted { lhs, rhs in
                if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
                return lhs.distance < rhs.distance
            }
            .prefix(limit)
            .map(\.item)
    }

    private static func nearbyProbeRings(
        around coordinate: CLLocationCoordinate2D
    ) -> [[CLLocationCoordinate2D]] {
        let center = MKMapPoint(coordinate)
        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(coordinate.latitude)
        let radii: [CLLocationDistance] = [35, 70, 120, 200, 320]
        let bearings = stride(from: 0.0, to: 360.0, by: 45.0)

        return radii.map { radius in
            bearings.map { bearing in
                let angle = bearing * .pi / 180
                let mapPointRadius = radius / metersPerMapPoint
                let point = MKMapPoint(
                    x: center.x + cos(angle) * mapPointRadius,
                    y: center.y + sin(angle) * mapPointRadius
                )
                return point.coordinate
            }
        }
    }

    static func displayAddress(for mapItem: MKMapItem, fallback: String) -> String {
        if let fullAddress = mapItem.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true) {
            return fullAddress
        }

        if let fullAddress = mapItem.address?.fullAddress {
            return fullAddress.replacingOccurrences(of: "\n", with: ", ")
        }

        return mapItem.name ?? fallback
    }
}
