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
        case .property: return "Address Search"
        case .filter: return "Contact Filter"
        }
    }

    var systemImage: String {
        switch self {
        case .property: return "building.2.crop.circle"
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

    var activeContactFilter: ContactSearchFilter?
    var contactFilterResultCount: Int = 0
    var selectedListName: String = "Prospects"
    var animationNamespace: Namespace.ID
    var onSubmit: () -> Void
    var onSubmitContactFilter: () -> Void
    var onClearContactFilter: () -> Void
    var onSelectResult: (MKLocalSearchCompletion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {

                if isExpanded {
                    
                    VStack(alignment: .leading, spacing: 10) {
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
                                    
                                    // Collapse search bar
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.34), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
                    .matchedGeometryEffect(id: "search", in: animationNamespace)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    smartSearchPill
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.34), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
                        .matchedGeometryEffect(id: "search", in: animationNamespace)
                        .onChange(of: isFocused) { _, newValue in
                            guard newValue else { return }
                            MapScreenHapticsController.shared.lightTap()
                            MapScreenSoundController.shared.playPropertyOpen()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isExpanded = true
                            }
                        }
                }
            }

            if !isExpanded, let activeContactFilter, !activeContactFilter.isEmpty {
                appliedFilterChip(activeContactFilter)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var smartSearchPill: some View {
        Button {
            MapScreenHapticsController.shared.lightTap()
            MapScreenSoundController.shared.playPropertyOpen()
            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                isExpanded = true
            }
            DispatchQueue.main.async {
                isFocused = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(activeContactFilter == nil ? "Search map" : "Search or refine")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(activeContactFilter == nil ? "Address, prospect, or referral" : "\(selectedListName): \(contactFilterResultCount) match\(contactFilterResultCount == 1 ? "" : "es")")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .padding(.horizontal, 9)
            .frame(height: 54)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Map Search")
    }

    private func appliedFilterChip(_ filter: ContactSearchFilter) -> some View {
        HStack(spacing: 8) {
            Image(systemName: filter.field.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)

            Text(filter.displayText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(contactFilterResultCount)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.blue)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.12), in: Capsule())

            Button(action: onClearContactFilter) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear Contact Filter")
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(.regularMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    private var searchScopeMenu: some View {
        HStack(spacing: 8) {
            ForEach(MapSearchMode.allCases) { mode in
                Button {
                    switchSearchMode(to: mode)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 14, weight: .semibold))

                        Text(mode.label)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .foregroundStyle(searchMode == mode ? .white : .blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        Capsule()
                            .fill(searchMode == mode ? Color.blue : Color.blue.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.blue.opacity(searchMode == mode ? 0 : 0.24), lineWidth: 1)
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.label)
            }
        }
        .padding(.horizontal, 2)
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
