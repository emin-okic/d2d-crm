//
//  SearchCompleterViewModel.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/17/25.
//


import Foundation
import MapKit
import Combine

@MainActor
class SearchCompleterViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    @Published private(set) var secondaryAddress = ""

    private let completer: MKLocalSearchCompleter

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
        self.completer.resultTypes = .address
    }

    func updateQuery(_ query: String) {
        let components = Self.addressComponents(from: query)
        secondaryAddress = Self.canonicalSecondaryAddress(components.secondaryAddress)

        if components.baseAddress.isEmpty {
            clear()
        } else {
            // MapKit commonly drops address completions after a secondary-address
            // designator is entered. Keep completing the building address instead.
            completer.queryFragment = components.baseAddress
        }
    }

    func clear() {
        completer.queryFragment = ""
        results = []
        secondaryAddress = ""
    }

    func addressByAppendingSecondaryAddress(to address: String) -> String {
        Self.appendingSecondaryAddress(secondaryAddress, to: address)
    }

    nonisolated static func addressComponents(from query: String) -> (baseAddress: String, secondaryAddress: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", "") }

        let pattern = #"(?i)(?:[\s,]+)((?:unit|apartment|apt\.?|suite|ste\.?|flat|room|rm\.?|lot|#)(?:\s*[-#]?\s*(?:\d[\p{L}\p{N}-]*|[\p{L}]{1,3}\d*))?)\s*$"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(
                in: trimmed,
                range: NSRange(trimmed.startIndex..., in: trimmed)
              ),
              let suffixRange = Range(match.range(at: 1), in: trimmed),
              let fullMatchRange = Range(match.range(at: 0), in: trimmed) else {
            return (trimmed, "")
        }

        let baseAddress = String(trimmed[..<fullMatchRange.lowerBound])
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",")))
        guard !baseAddress.isEmpty else { return (trimmed, "") }

        return (baseAddress, String(trimmed[suffixRange]).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    nonisolated static func appendingSecondaryAddress(_ secondaryAddress: String, to address: String) -> String {
        let syntheticAddress = "1 Main St \(secondaryAddress)"
        guard let unit = AddressCanonicalizer.parse(syntheticAddress).unit else {
            return AddressCanonicalizer.standardizedAddress(address)
        }

        return AddressCanonicalizer.appendingUnit(unit, to: address)
    }

    nonisolated private static func canonicalSecondaryAddress(_ secondaryAddress: String) -> String {
        let syntheticAddress = "1 Main St \(secondaryAddress)"
        guard let unit = AddressCanonicalizer.parse(syntheticAddress).unit else { return "" }
        return "Unit \(unit)"
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Delegate callback is nonisolated → marshal to MainActor
        Task { @MainActor in
            if self.completer.queryFragment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.results = []
            } else {
                self.results = self.completer.results
            }
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer failed: \(error)")
    }
}
