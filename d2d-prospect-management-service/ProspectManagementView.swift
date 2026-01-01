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

    var body: some View {
        VStack(spacing: 16) {
            
            ProspectFilterRow(
                searchText: $searchText,
                isSearchFocused: $isSearchFocused,
                onSubmit: {
                    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }

                    if let match = prospects.first(where: {
                        $0.fullName.localizedCaseInsensitiveContains(trimmed) ||
                        $0.address.localizedCaseInsensitiveContains(trimmed)
                    }) {
                        selectedProspect = match
                    }
                }
            )
            
            ProspectHeaderView(totalProspects: totalProspects)

            // Toggle chips under header (uses shared binding now)
            ToggleChipsView(selectedList: $selectedList)

            ProspectContainerView(
                selectedList: $selectedList,
                searchText: $searchText,
                selectedProspect: $selectedProspect,
                isDeleting: $isDeleting,
                selectedProspects: $selectedProspects
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
                    searchText = ""
                    onSave()
                },
                onDismiss: {
                    suggestedProspect = nil
                }
            )
        }
    }
}
