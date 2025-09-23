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
    @State private var suggestedProspect: Prospect?
    @State private var suggestionSourceIndex = 0

    @State private var isSearchExpanded: Bool = false
    @FocusState private var isSearchFocused: Bool

    // Menu + overlays
    @State private var showAddOptionsMenu = false
    @State private var showingImportFromContacts = false
    @State private var showImportSuccess = false

    @Query private var prospects: [Prospect]

    var body: some View {
        NavigationView {
            ZStack {
                if selectedList == "Prospects" {
                    ProspectManagementView(
                        searchText: $searchText,
                        suggestedProspect: $suggestedProspect,
                        selectedList: $selectedList,
                        onSave: onSave
                    )
                } else {
                    CustomerManagementView(
                        searchText: $searchText,
                        selectedList: $selectedList,
                        onSave: onSave
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
                        VStack {
                            Text("Contacts imported successfully!")
                                .padding()
                                .background(Color.green.opacity(0.95))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 6)
                                .transition(.scale.combined(with: .opacity))
                                .zIndex(9999)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
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
            .onChange(of: selectedList) { newValue in
                if newValue == "Prospects" {
                    Task { await fetchNextSuggestedNeighbor() }
                }
            }
        }
    }

    // MARK: - Suggestion fetching
    private func fetchNextSuggestedNeighbor() async {
        let controller = DatabaseController.shared
        let customerProspects = prospects.filter { $0.list == "Customers" }
        guard !customerProspects.isEmpty else {
            suggestedProspect = nil
            return
        }

        var attemptIndex = suggestionSourceIndex
        var found: Prospect?

        for _ in 0..<customerProspects.count {
            let customer = customerProspects[attemptIndex]

            let result = await withCheckedContinuation { (continuation: CheckedContinuation<Prospect?, Never>) in
                controller.geocodeAndSuggestNeighbor(from: customer.address) { address in
                    if let addr = address,
                       !prospects.contains(where: { $0.address.caseInsensitiveCompare(addr) == .orderedSame }) {
                        let suggested = Prospect(
                            fullName: "Suggested Neighbor",
                            address: addr,
                            count: 0,
                            list: "Prospects"
                        )
                        continuation.resume(returning: suggested)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }

            if let valid = result {
                found = valid
                suggestionSourceIndex = (attemptIndex + 1) % customerProspects.count
                break
            }

            attemptIndex = (attemptIndex + 1) % customerProspects.count
        }

        suggestedProspect = found
    }
}
