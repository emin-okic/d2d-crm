//
//  SearchBarController.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import Foundation
import MapKit
import Contacts

@MainActor
enum SearchBarController {
    /// Resolves a selected search completion to a general address string (e.g., map title).
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
    
    static func resolveAndSelectAddress(
        from completion: MKLocalSearchCompletion,
        onResolved: @escaping (String) -> Void
    ) {
        Task { @MainActor in
            guard let selectedAddress = await resolveAddress(from: completion) else { return }
            onResolved(selectedAddress)
        }
    }

    private static func displayAddress(for mapItem: MKMapItem, fallback: String) -> String {
        if let fullAddress = mapItem.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true) {
            return fullAddress
        }

        if let fullAddress = mapItem.address?.fullAddress {
            return fullAddress.replacingOccurrences(of: "\n", with: ", ")
        }

        return mapItem.name ?? fallback
    }
}
