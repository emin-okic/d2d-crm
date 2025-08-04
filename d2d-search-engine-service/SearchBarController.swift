//
//  SearchBarController.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import Foundation
import MapKit

enum SearchBarController {
    /// Resolves a selected search completion to a full address string.
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
}
