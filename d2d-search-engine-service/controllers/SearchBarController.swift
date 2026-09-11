//
//  SearchBarController.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import Foundation
import MapKit
import CoreLocation
import Contacts

enum SearchBarController {
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
        let searchRegion = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 450,
            longitudinalMeters: 450
        )
        let queries = ["home", "house", "residential address", "address"]
        var uniqueItems: [String: MKMapItem] = [:]

        for query in queries where uniqueItems.count < limit {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = .address
            request.region = searchRegion

            do {
                let response = try await MKLocalSearch(request: request).start()
                for item in response.mapItems {
                    let address = displayAddress(for: item, fallback: item.name ?? query)
                    guard !address.isEmpty else { continue }
                    uniqueItems[address.lowercased()] = item
                }
            } catch {
                print("❌ Nearby home search failed:", error.localizedDescription)
            }
        }

        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return uniqueItems.values
            .sorted { lhs, rhs in
                let lhsDistance = lhs.location.distance(from: origin)
                let rhsDistance = rhs.location.distance(from: origin)
                return lhsDistance < rhsDistance
            }
            .prefix(limit)
            .map { $0 }
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
