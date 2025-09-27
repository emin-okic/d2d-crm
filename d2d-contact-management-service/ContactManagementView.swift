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
    @State private var showAddOptionsMenu = false
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
                        onSave: onSave
                    )
                } else {
                    CustomerManagementView(
                        searchText: $searchText,
                        selectedList: $selectedList,
                        onSave: onSave,
                        showingAddCustomer: $showingAddCustomer
                    )
                }

                // Dim background if menu is open
                if showAddOptionsMenu {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture { withAnimation { showAddOptionsMenu = false } }
                }

                // Toolbar
                ContactsToolbarView(
                    searchText: $searchText,
                    isSearchExpanded: $isSearchExpanded,
                    isSearchFocused: $isSearchFocused,
                    onAddTapped: {
                        if selectedList == "Prospects" {
                            withAnimation(.spring()) { showAddOptionsMenu = true }
                        } else {
                            // Customer add flow is inside CustomerManagementView
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
                    onSave: onSave
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
                    if showAddOptionsMenu {
                        VStack {
                            Spacer()
                            HStack {
                                AddProspectOptionsMenu(
                                    onAddManually: {
                                        withAnimation { showAddOptionsMenu = false }
                                        // Prospect create flow handled in ProspectManagementView
                                        showingAddProspect = true
                                    },
                                    onImportFromContacts: {
                                        withAnimation { showAddOptionsMenu = false }
                                        showingImportFromContacts = true
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                                .zIndex(1000)
                                Spacer()
                            }
                            .padding(.leading, 40)
                            .padding(.bottom, 80)
                        }
                        .ignoresSafeArea()
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
