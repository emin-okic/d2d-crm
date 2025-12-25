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
            .overlay(
                Group {
                    if showingAddProspect {
                        ProspectCreateStepperView { newProspect in
                            modelContext.insert(newProspect)
                            try? modelContext.save()

                            searchText = ""
                            showingAddProspect = false
                            onSave()
                        } onCancel: {
                            showingAddProspect = false
                        }
                        .frame(width: 300, height: 300)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(radius: 8)
                        .position(x: UIScreen.main.bounds.midX,
                                  y: UIScreen.main.bounds.midY * 0.9)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(2000)
                    }
                }
            )
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
