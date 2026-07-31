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

    private let completer: MKLocalSearchCompleter

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
        self.completer.resultTypes = .address
    }

    func updateQuery(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedQuery.isEmpty {
            clear()
        } else {
            completer.queryFragment = query
        }
    }

    func clear() {
        completer.queryFragment = ""
        results = []
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
