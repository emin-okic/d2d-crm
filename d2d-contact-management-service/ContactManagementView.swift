//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData
import ContactsUI

struct ContactManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedList: String
    var onSave: () -> Void

    // Shared state
    @StateObject private var controller = ContactManagerController()
    @State private var suggestedProspect: Prospect?
    @State private var suggestionSourceIndex = 0

    @State private var isSearchExpanded: Bool = false
    @FocusState private var isSearchFocused: Bool

    // Menu + overlays
    @State private var showingImportFromContacts = false
    @State private var showImportSuccess = false

    @Query private var prospects: [Prospect]
    @Query private var customers: [Customer]
    
    @State private var showingAddProspect = false
    
    @State private var showingAddCustomer = false
    
    @Binding var searchContext: AppSearchContext
    @Binding var searchText: String
    
    init(
        searchText: Binding<String>,
        searchContext: Binding<AppSearchContext>,
        selectedList: Binding<String>,
        onSave: @escaping () -> Void
    ) {
        self._searchText = searchText
        self._searchContext = searchContext
        self._selectedList = selectedList
        self.onSave = onSave

        self._prospects = Query()
        self._customers = Query()
    }

    var body: some View {
        NavigationView {
            ZStack {
                if selectedList == "Prospects" {
                    ProspectManagementView(
                        searchText: $searchText,
                        suggestedProspect: $controller.suggestedProspect,
                        selectedList: $selectedList,
                        isSearchExpanded: $isSearchExpanded,
                        isSearchFocused: $isSearchFocused,
                        onSave: onSave
                    )
                } else {
                    CustomerManagementView(
                        searchText: $searchText,
                        selectedList: $selectedList,
                        isSearchExpanded: $isSearchExpanded,
                        isSearchFocused: $isSearchFocused,
                        onSave: onSave,
                        showingAddCustomer: $showingAddCustomer
                    )
                }

                // Toolbar
                ContactsToolbarView(
                    searchText: $searchText,
                    isSearchExpanded: $isSearchExpanded,
                    isSearchFocused: $isSearchFocused,
                    onAddTapped: {
                        if selectedList == "Prospects" {
                            withAnimation(.spring()) {
                                showingImportFromContacts = true
                            }
                        } else {
                            showingAddCustomer = true
                        }
                    }
                )
            }
            .navigationTitle("")
            .overlay(
                ImportOverlayView(
                    showingImportFromContacts: $showingImportFromContacts,
                    showImportSuccess: $showImportSuccess,
                    selectedList: $selectedList,
                    searchText: $searchText,
                    prospects: prospects,
                    modelContext: modelContext,
                    onSave: onSave,
                    onAddManually: {
                        showingAddProspect = true
                    }
                )
            )
            .overlay(
                Group {
                    if showImportSuccess {
                        ToastMessageView(message: "Contacts imported successfully!")
                    }
                }
            )
            .sheet(isPresented: $showingAddProspect) {
                ProspectCreateStepperView { newProspect in
                    modelContext.insert(newProspect)
                    try? modelContext.save()

                    searchText = ""
                    showingAddProspect = false
                    onSave()
                } onCancel: {
                    showingAddProspect = false
                }
                .presentationDetents([.fraction(0.5)]) // 50% of screen height
                .presentationDragIndicator(.visible)    // optional: show the drag handle
            }
            .onChange(of: selectedList) { newValue in
                if newValue == "Prospects" {
                    Task {
                        await controller.fetchNextSuggestedNeighbor(
                            from: customers,
                            existingProspects: prospects
                        )
                    }
                }
            }
        }
    }
}
