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
    var onSubmit: () -> Void
    var onSelectResult: (MKLocalSearchCompletion) -> Void

    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchField

            SearchSuggestionsListView(
                isVisible: isFocused,
                results: viewModel.results,
                onSelect: onSelectResult
            )
            .padding(.top, 2)
            .padding(.bottom, isFocused && !viewModel.results.isEmpty ? 10 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.22), value: viewModel.results.count)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)

            TextField("Search properties or addresses", text: $searchText, onCommit: {
                onSubmit()
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
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(height: 48)
        .background(Color(.secondarySystemBackground).opacity(0.78), in: Capsule())
    }

    private func cancelOrClearSearch() {
        if searchText.isEmpty {
            onCancel()
        } else {
            searchText = ""
            viewModel.clear()
        }
    }
}

struct MapContactFilterSearchView: View {
    @Binding var searchText: String
    @Binding var selectedField: ContactSearchField
    @FocusState.Binding var isFocused: Bool
    var onSubmit: () -> Void
    var onClear: () -> Void
    var onCancel: () -> Void

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
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(Color.blue.opacity(0.1), in: Capsule())
                }
                .menuOrder(.fixed)

                TextField("Filter properties", text: $searchText, onCommit: {
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
            .padding(.leading, 10)
            .padding(.trailing, 8)
            .frame(height: 48)
            .background(Color(.secondarySystemBackground).opacity(0.78), in: Capsule())
        }
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
