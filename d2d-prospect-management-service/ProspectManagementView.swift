//
//  ProspectManagementView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import SwiftUI
import SwiftData

struct ProspectManagementView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Binding var searchText: String
    @Binding var selectedSearchField: ContactSearchField
    @Binding var activeSearchFilter: ContactSearchFilter?
    @Binding var suggestedProspect: Prospect?
    @Binding var suggestedNeighborSourceAddress: String?
    @Binding var selectedList: String
    
    var onSave: () -> Void

    @Query private var prospects: [Prospect]

    private var totalProspects: Int {
        prospects.filter { $0.list == "Prospects" }.count
    }
    
    @Binding var selectedProspect: Prospect?
    
    @FocusState<Bool>.Binding var isSearchFocused: Bool
    
    @Binding var isDeleting: Bool
    @Binding var selectedProspects: Set<Prospect>
    var onClearSearchFilter: () -> Void
    var onNavigateToMap: (MapContactSelection) -> Void = { _ in }
    var onProspectOpenRequested: (Prospect) -> Bool = { _ in false }

    @State private var isShowingSuggestedProspectSheet = false
    @State private var dismissedSuggestionAddress: String?

    private var filteredProspectCount: Int {
        let base = prospects.filter { $0.list == selectedList }
        guard let filter = activeSearchFilter, !filter.isEmpty else { return base.count }
        return base.filter { $0.matches(filter) }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            
            ProspectFilterRow(
                searchText: $searchText,
                selectedField: $selectedSearchField,
                isSearchFocused: $isSearchFocused,
                onSubmit: applySearchFilter,
                onClear: onClearSearchFilter
            )

            if let filter = activeSearchFilter, !filter.isEmpty {
                ContactFilterBanner(
                    filter: filter,
                    resultCount: filteredProspectCount,
                    listName: selectedList,
                    onClear: onClearSearchFilter
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if shouldShowSuggestionBanner, let suggestedProspect {
                SuggestedProspectBannerView(
                    suggestion: suggestedProspect,
                    onOpen: {
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        isShowingSuggestedProspectSheet = true
                    },
                    onDismiss: dismissSuggestionBanner
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            ProspectHeaderView(totalProspects: totalProspects)

            // Toggle chips under header (uses shared binding now)
            ToggleChipsView(selectedList: $selectedList)

            ProspectContainerView(
                selectedList: $selectedList,
                activeSearchFilter: $activeSearchFilter,
                selectedProspect: $selectedProspect,
                isDeleting: $isDeleting,
                selectedProspects: $selectedProspects,
                onNavigateToMap: onNavigateToMap,
                onProspectOpenRequested: onProspectOpenRequested
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: shouldShowSuggestionBanner)
        .onChange(of: suggestedProspect?.address) { _, newAddress in
            guard newAddress != dismissedSuggestionAddress else { return }
            dismissedSuggestionAddress = nil
            isShowingSuggestedProspectSheet = false
        }
        .sheet(isPresented: $isShowingSuggestedProspectSheet, onDismiss: clearSuggestion) {
            if let suggestion = suggestedProspect {
                SuggestedProspectSheetView(
                    suggestion: suggestion,
                    nearbyCustomerAddress: suggestedNeighborSourceAddress,
                    onAdd: {
                        modelContext.insert(suggestion)
                        try? modelContext.save()
                        clearSuggestion()
                        onClearSearchFilter()
                        onSave()
                    },
                    onDismiss: clearSuggestion
                )
            }
        }
    }

    private var shouldShowSuggestionBanner: Bool {
        guard let suggestedProspect else { return false }
        return suggestedProspect.address != dismissedSuggestionAddress && !isShowingSuggestedProspectSheet
    }

    private func dismissSuggestionBanner() {
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()
        dismissedSuggestionAddress = suggestedProspect?.address
    }

    private func clearSuggestion() {
        dismissedSuggestionAddress = suggestedProspect?.address
        suggestedProspect = nil
        suggestedNeighborSourceAddress = nil
        isShowingSuggestedProspectSheet = false
    }

    private func applySearchFilter() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onClearSearchFilter()
            return
        }

        activeSearchFilter = ContactSearchFilter(field: selectedSearchField, query: trimmed)
        searchText = ""
        isSearchFocused = false
    }
}
