//
//  SearchBarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//
import SwiftUI
import MapKit
import CoreLocation
import SwiftData
import Combine
import Contacts

struct SearchBarView: View {
    @Binding var searchText: String
    @FocusState.Binding var isFocused: Bool
    @ObservedObject var viewModel: SearchCompleterViewModel
    var nearbyHomeSuggestions: [PropertySearchSuggestion] = []
    var isLoadingNearbyHomes = false
    var onSubmit: () -> Void
    var onNearbyHomes: () -> Void = {}
    var onSelectResult: (MKLocalSearchCompletion) -> Void
    var onSelectNearbyHome: (MKMapItem) -> Void = { _ in }

    var onCancel: () -> Void

    @AppStorage("recentMapPropertySearches") private var recentSearchesStorage: String = ""

    private var recentSearches: [String] {
        recentSearchesStorage
            .split(separator: "|")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private var visibleSuggestions: [PropertySearchSuggestion] {
        nearbyHomeSuggestions.isEmpty ? viewModel.results.map(PropertySearchSuggestion.init(completion:)) : nearbyHomeSuggestions
    }

    private var hasVisibleSuggestions: Bool {
        !visibleSuggestions.isEmpty || isLoadingNearbyHomes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            searchField

            propertySuggestionChips

            SearchSuggestionsListView(
                isVisible: isFocused,
                suggestions: visibleSuggestions,
                isLoading: isLoadingNearbyHomes,
                onSelect: selectSuggestion
            )
            .padding(.top, 4)
            .padding(.bottom, isFocused && hasVisibleSuggestions ? 12 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.22), value: viewModel.results.count)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            TextField("Search address", text: $searchText, onCommit: {
                submitSearch()
            })
            .focused($isFocused)
            .font(.subheadline.weight(.medium))
            .foregroundColor(.primary)
            .textInputAutocapitalization(.words)
            .submitLabel(.search)

            Button(action: cancelOrClearSearch) {
                Image(systemName: searchText.isEmpty ? "xmark" : "xmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.leading, 8)
        .padding(.trailing, 6)
        .padding(.vertical, 7)
        .background(Color(.systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var propertySuggestionChips: some View {
        if isFocused {
            let chips = recentSearches.isEmpty ? ["Nearby homes"] : Array(recentSearches.prefix(3))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips, id: \.self) { chip in
                        Button {
                            selectChip(chip)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: recentSearches.contains(chip) ? "clock.arrow.circlepath" : "sparkle.magnifyingglass")
                                    .font(.caption.weight(.semibold))

                                Text(chip)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func cancelOrClearSearch() {
        if searchText.isEmpty {
            onCancel()
        } else {
            searchText = ""
            viewModel.clear()
        }
    }

    private func submitSearch() {
        storeRecentSearch(searchText)
        onSubmit()
    }

    private func selectChip(_ chip: String) {
        searchText = chip
        isFocused = true

        if chip == "Nearby homes" {
            viewModel.clear()
            onNearbyHomes()
        } else {
            viewModel.updateQuery(chip)
        }
    }

    private func selectSuggestion(_ suggestion: PropertySearchSuggestion) {
        if let completion = suggestion.completion {
            storeRecentSearch(completion.title)
            onSelectResult(completion)
        } else if let mapItem = suggestion.mapItem {
            storeRecentSearch(suggestion.title)
            onSelectNearbyHome(mapItem)
        }
    }

    private func storeRecentSearch(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var values = recentSearches.filter { $0.localizedCaseInsensitiveCompare(trimmed) != .orderedSame }
        values.insert(trimmed, at: 0)
        recentSearchesStorage = values.prefix(5).joined(separator: "|")
    }
}

struct MapContactFilterSearchView: View {
    @Binding var searchText: String
    @Binding var selectedField: ContactSearchField
    @FocusState.Binding var isFocused: Bool
    var onSubmit: () -> Void
    var onClear: () -> Void
    var onCancel: () -> Void

    private var priorityFields: [ContactSearchField] {
        [.all, .name, .address, .phone, .email]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Menu {
                    ForEach(ContactSearchField.allCases) { field in
                        Button {
                            selectedField = field
                        } label: {
                            Label(field.label, systemImage: field.systemImage)
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: selectedField.systemImage)
                            .font(.caption.weight(.semibold))

                        Text(selectedField.label)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)

                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1), in: Capsule())
                }
                .menuOrder(.fixed)

                TextField("Filter referrals or contacts", text: $searchText, onCommit: {
                    onSubmit()
                })
                .focused($isFocused)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

                Button(action: clearOrCancel) {
                    Image(systemName: searchText.isEmpty ? "xmark" : "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 8)
            .padding(.trailing, 6)
            .padding(.vertical, 7)
            .background(Color(.systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            if isFocused {
                filterChips
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(priorityFields) { field in
                    Button {
                        selectedField = field
                        isFocused = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: field.systemImage)
                                .font(.caption.weight(.semibold))

                            Text(field.label)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(selectedField == field ? .white : .blue)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(selectedField == field ? Color.blue : Color.blue.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func clearOrCancel() {
        if searchText.isEmpty {
            onCancel()
        } else {
            searchText = ""
            onClear()
        }
    }
}
