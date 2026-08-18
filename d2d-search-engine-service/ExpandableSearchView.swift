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
        case .property: return "Property"
        case .filter: return "Filter"
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

    var animationNamespace: Namespace.ID
    var onSubmit: () -> Void
    var onSubmitContactFilter: () -> Void
    var onClearContactFilter: () -> Void
    var onSelectResult: (MKLocalSearchCompletion) -> Void
    
    private let floatingButtonSize: CGFloat = 50

    var body: some View {
        VStack {
            
            HStack {

                if isExpanded {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        searchModePicker

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
                    .matchedGeometryEffect(id: "search", in: animationNamespace)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    Button {
                        
                        // ✅ Haptics
                        MapScreenHapticsController.shared.lightTap()
                        
                        // ✅ Sound
                        MapScreenSoundController.shared.playPropertyOpen()
                        
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isExpanded = true
                            isFocused = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: floatingButtonSize, height: floatingButtonSize)
                            .background(Circle().fill(Color.blue))
                    }
                    .matchedGeometryEffect(id: "search", in: animationNamespace)
                    .shadow(radius: 4)
                }
            }
        }
    }

    private var searchModePicker: some View {
        Picker("Map Search Mode", selection: $searchMode) {
            ForEach(MapSearchMode.allCases) { mode in
                Label(mode.label, systemImage: mode.systemImage)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: searchMode) { _, newValue in
            resetPropertySearchState()
            contactSearchText = ""
            if newValue == .property {
                isFocused = true
            } else {
                viewModel.clear()
                isFocused = true
            }
        }
    }

    private func resetPropertySearchState() {
        searchText = ""
        viewModel.clear()
    }
}
