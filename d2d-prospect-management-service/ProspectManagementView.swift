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
    @Binding var selectedList: String   // 👈 add this
    
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

    private var filteredProspectCount: Int {
        let base = prospects.filter { $0.list == selectedList }
        guard let filter = activeSearchFilter, !filter.isEmpty else { return base.count }
        return base.filter { $0.matches(filter) }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            
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
            .padding(.vertical, 10)
        }
        .sheet(item: $suggestedProspect) { suggestion in
            SuggestedProspectSheetView(
                suggestion: suggestion,
                onAdd: {
                    modelContext.insert(suggestion)
                    try? modelContext.save()
                    suggestedProspect = nil
                    onClearSearchFilter()
                    onSave()
                },
                onDismiss: {
                    suggestedProspect = nil
                }
            )
        }
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
