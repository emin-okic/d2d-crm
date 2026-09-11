//
//  SearchSuggestionsListView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import SwiftUI
import MapKit

struct PropertySearchSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let badge: String
    let completion: MKLocalSearchCompletion?
    let mapItem: MKMapItem?

    init(completion: MKLocalSearchCompletion) {
        self.title = completion.title
        self.subtitle = completion.subtitle.isEmpty ? "Address match" : completion.subtitle
        self.badge = "Property"
        self.completion = completion
        self.mapItem = nil
    }

    init(mapItem: MKMapItem, fallbackTitle: String) {
        let placemarkTitle = mapItem.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = SearchBarController.displayAddress(for: mapItem, fallback: fallbackTitle)
        let title = placemarkTitle.flatMap { $0.isEmpty ? nil : $0 } ?? address

        self.title = title
        self.subtitle = address == self.title ? "Nearby address" : address
        self.badge = "Nearby"
        self.completion = nil
        self.mapItem = mapItem
    }
}

struct SearchSuggestionsListView: View {
    var isVisible: Bool
    var suggestions: [PropertySearchSuggestion]
    var isLoading: Bool = false
    var onSelect: (PropertySearchSuggestion) -> Void

    private let maxVisibleResults = 5

    var body: some View {
        if isVisible && (!suggestions.isEmpty || isLoading) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text("Suggested properties")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("\(min(suggestions.count, maxVisibleResults))")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.blue)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(Color.blue.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 11)
                .padding(.bottom, 7)

                ForEach(Array(suggestions.prefix(maxVisibleResults).enumerated()), id: \.element.id) { index, suggestion in
                    suggestionButton(for: suggestion)

                    if index < min(suggestions.count, maxVisibleResults) - 1 {
                        Divider()
                            .padding(.leading, 58)
                    }
                }
            }
            .background(Color(.systemBackground).opacity(0.94), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, maxHeight: 288)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(10)
        }
    }

    private func suggestionButton(for suggestion: PropertySearchSuggestion) -> some View {
        Button {
            onSelect(suggestion)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(suggestion.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(suggestion.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(suggestion.badge)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(.secondarySystemBackground), in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
