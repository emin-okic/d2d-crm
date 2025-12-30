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
    @State private var searchText: String = ""
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
    
    @State private var selectedProspect: Prospect?
    @State private var selectedCustomer: Customer?

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
                        onSave: onSave,
                        selectedProspect: $selectedProspect
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
                    },
                    onSearchSubmit: handleSearchSubmit
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
    
    func matchesSearch(_ text: String, name: String, address: String) -> Bool {
        let query = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return false }

        return name.lowercased().contains(query)
            || address.lowercased().contains(query)
    }
    
    func firstMatchingProspect(
        searchText: String,
        prospects: [Prospect]
    ) -> Prospect? {
        prospects.first {
            matchesSearch(searchText, name: $0.fullName, address: $0.address)
        }
    }

    func firstMatchingCustomer(
        searchText: String,
        customers: [Customer]
    ) -> Customer? {
        customers.first {
            matchesSearch(searchText, name: $0.fullName, address: $0.address)
        }
    }
    
    private func handleSearchSubmit() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if selectedList == "Prospects",
           let match = firstMatchingProspect(searchText: trimmed, prospects: prospects) {
            selectedProspect = match
        }

        if selectedList == "Customers",
           let match = firstMatchingCustomer(searchText: trimmed, customers: customers) {
            selectedCustomer = match
        }

        withAnimation {
            isSearchExpanded = false
            isSearchFocused = false
        }
    }
}
