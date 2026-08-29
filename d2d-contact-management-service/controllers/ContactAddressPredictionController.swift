//
//  ContactAddressPredictionController.swift
//  d2d-studio
//
//  Created by Codex on 8/29/26.
//

import Foundation
import MapKit

@MainActor
enum ContactAddressPredictionController {
    static func resolvePrediction(
        typedAddress: String,
        completions: [MKLocalSearchCompletion]
    ) async -> String? {
        let trimmedAddress = typedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else { return nil }

        if let firstCompletion = completions.first,
           let resolvedAddress = await SearchBarController.resolveAddress(from: firstCompletion) {
            return resolvedAddress
        }

        guard let mapItem = await SearchBarController.resolveFreeformSearch(query: trimmedAddress) else {
            return nil
        }

        return displayAddress(for: mapItem, fallback: trimmedAddress)
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
