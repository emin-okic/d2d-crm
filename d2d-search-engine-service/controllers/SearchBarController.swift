//
//  SearchBarController.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import Foundation
import MapKit
import Contacts

enum SearchBarController {
    /// Resolves a selected search completion to a general address string (e.g., map title).
    static func resolveAddress(from completion: MKLocalSearchCompletion) async -> String? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            return response.mapItems.first?.placemark.title ?? completion.title
        } catch {
            print("❌ Error resolving address: \(error.localizedDescription)")
            return nil
        }
    }

    /// Resolves and formats a selected search completion to a full postal address.
    static func resolveFormattedPostalAddress(from completion: MKLocalSearchCompletion) async -> String? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else { return nil }

            if let postalAddress = item.placemark.postalAddress {
                let formatter = CNPostalAddressFormatter()
                return formatter.string(from: postalAddress).replacingOccurrences(of: "\n", with: ", ")
            } else {
                return item.name ?? completion.title
            }
        } catch {
            print("❌ Error formatting postal address: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func handleResolvedSearch(
        query: String,
        onResolved: (String) -> Void
    ) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        onResolved(trimmed)
    }
    
    static func resolveAndSelectAddress(
        from completion: MKLocalSearchCompletion,
        onResolved: @escaping (String) -> Void
    ) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            guard let item = response?.mapItems.first else { return }
            let selectedAddress = item.placemark.title ?? completion.title
            DispatchQueue.main.async {
                onResolved(selectedAddress)
            }
        }
    }
}
