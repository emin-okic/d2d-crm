//
//  ExpandableSearchView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import SwiftUI
import MapKit

enum MapSearchMode: String, CaseIterable, Identifiable {
    case property
    case filter

    var id: String { rawValue }

    var label: String {
        switch self {
        case .property: return "Address"
        case .filter: return "Contacts"
        }
    }

    var systemImage: String {
        switch self {
        case .property: return "magnifyingglass"
        case .filter: return "line.3.horizontal.decrease.circle"
        }
    }
}

struct ExpandableSearchView: View {
    @Binding var searchText: String
    @Binding var contactSearchText: String
    @Binding var selectedContactSearchField: ContactSearchField
    @Binding var searchMode: MapSearchMode
    @Binding var isExpanded: Bool
    @FocusState.Binding var isFocused: Bool

    @ObservedObject var viewModel: SearchCompleterViewModel

    var animationNamespace: Namespace.ID
    var onSubmit: () -> Void
    var onSubmitContactFilter: () -> Void
    var onClearContactFilter: () -> Void
    var onSelectResult: (MKLocalSearchCompletion) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(Color.secondary.opacity(0.32))
                .frame(width: 42, height: 5)
                .padding(.top, 7)

            VStack(alignment: .leading, spacing: 12) {
                searchScopeMenu

                if searchMode == .property {
                    SearchBarView(
                        searchText: $searchText,
                        isFocused: $isFocused,
                        viewModel: viewModel,
                        onSubmit: {
                            onSubmit()
                            resetPropertySearchState()
                            withAnimation { isExpanded = false }
                        },
                        onSelectResult: {
                            onSelectResult($0)
                            resetPropertySearchState()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                                isFocused = false
                            }
                        },
                        onCancel: {
                            resetPropertySearchState()
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    )
                } else {
                    MapContactFilterSearchView(
                        searchText: $contactSearchText,
                        selectedField: $selectedContactSearchField,
                        isFocused: $isFocused,
                        onSubmit: {
                            onSubmitContactFilter()
                            withAnimation { isExpanded = false }
                        },
                        onClear: onClearContactFilter,
                        onCancel: {
                            contactSearchText = ""
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.38), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 22, x: 0, y: 10)
        .matchedGeometryEffect(id: "search", in: animationNamespace)
    }

    private var searchScopeMenu: some View {
        HStack(spacing: 8) {
            ForEach(MapSearchMode.allCases) { mode in
                Button {
                    switchSearchMode(to: mode)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 14, weight: .semibold))

                        Text(mode.label)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .foregroundStyle(searchMode == mode ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        Capsule()
                            .fill(searchMode == mode ? Color(.systemBackground).opacity(0.82) : Color.clear)
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.label)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground).opacity(0.66), in: Capsule())
    }

    private func switchSearchMode(to mode: MapSearchMode) {
        guard searchMode != mode else {
            isFocused = true
            return
        }

        searchMode = mode
        resetPropertySearchState()
        contactSearchText = ""
        if mode == .filter {
            viewModel.clear()
        }

        DispatchQueue.main.async {
            isFocused = true
        }
    }

    private func resetPropertySearchState() {
        searchText = ""
        viewModel.clear()
    }
}
