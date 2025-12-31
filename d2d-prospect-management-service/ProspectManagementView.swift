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

    var body: some View {
        VStack(spacing: 16) {
            ProspectHeaderView(totalProspects: totalProspects)

            // Toggle chips under header (uses shared binding now)
            ToggleChipsView(selectedList: $selectedList)

            ProspectContainerView(
                selectedList: $selectedList,  // 👈 use binding instead of .constant
                searchText: $searchText,
                selectedProspect: $selectedProspect
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
