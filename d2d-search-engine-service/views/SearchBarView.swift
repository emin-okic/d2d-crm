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
        VStack(alignment: .leading, spacing: 14) {
            searchField

            SearchSuggestionsListView(
                isVisible: isFocused,
                results: viewModel.results,
                onSelect: onSelectResult
            )
            .padding(.top, 4)
            .padding(.bottom, isFocused && !viewModel.results.isEmpty ? 12 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.22), value: viewModel.results.count)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

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
        .padding(.leading, 8)
        .padding(.trailing, 6)
        .padding(.vertical, 7)
        .background(Color(.systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
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
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
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
            .padding(.leading, 8)
            .padding(.trailing, 6)
            .padding(.vertical, 7)
            .background(Color(.systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
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
