//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData
import ContactsUI

/// A view that displays and manages a list of prospects
/// Users can filter by list type (e.g., "Prospects", "Customers"), add new prospects, and tap
/// a prospect to edit its details.
struct RolodexView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedList: String
    var onSave: () -> Void

    @State private var selectedProspectID: PersistentIdentifier?
    @State private var showingAddProspect = false
    @State private var suggestedProspect: Prospect?
    @State private var showingAddCustomer = false
    @State private var suggestionSourceIndex = 0 // Track which customer we’re pulling from
    
    @State private var showActivityOnboarding = false
    
    @State private var searchText: String = ""
    @State private var isSearchExpanded: Bool = false
    @FocusState private var isSearchFocused: Bool

    let availableLists = ["Prospects", "Customers"]
    @Query var prospects: [Prospect]
    @Query private var customers: [Customer]
    
    var onDoubleTap: ((Prospect) -> Void)? = nil
    
    @State private var showAddOptionsMenu = false
    @State private var showingImportFromContacts = false
    
    @State private var showImportSuccess = false

    init(
        selectedList: Binding<String>,
        onSave: @escaping () -> Void,
        onDoubleTap: ((Prospect) -> Void)? = nil
    ) {
        _selectedList = selectedList
        self.onSave = onSave
        self.onDoubleTap = onDoubleTap
        _prospects = Query()
        _customers = Query()
    }
    
    private var totalProspects: Int {
        prospects.filter { $0.list == "Prospects" }.count
    }

    private var totalCustomers: Int {
        prospects.filter { $0.list == "Customers" }.count
    }
    
    private var filteredCountText: String {
        let count = selectedList == "Prospects"
            ? prospects.filter { $0.list == "Prospects" }.count
            : prospects.filter { $0.list == "Customers" }.count
        let label = selectedList
        return "\(count) \(label)"
    }

    var body: some View {
        NavigationView {
            ZStack {
                
                // In RolodexView.body, inside NavigationView > ZStack > VStack:
                VStack(spacing: 16) {
                    
                    // Page Header
                    VStack(spacing: 10) {
                        
                        Text("Contacts")
                            .font(.largeTitle).fontWeight(.bold)
                            .padding(.top, 10)

                        Text(filteredCountText)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }

                    // Toggle chips
                    HStack(spacing: 10) {
                        toggleChip("Prospects", isOn: selectedList == "Prospects") { selectedList = "Prospects" }
                        toggleChip("Customers", isOn: selectedList == "Customers") { selectedList = "Customers" }
                    }
                    .padding(.horizontal, 20)
                    
                    // Suggested Prospect Card
                    Group {
                        
                        if selectedList == "Prospects", let suggestion = suggestedProspect {
                                            SuggestedProspectBannerView(
                                                suggestion: suggestion,
                                                onAdd: {
                                                    modelContext.insert(suggestion)
                                                    try? modelContext.save()
                                                    // Reset
                                                    suggestedProspect = nil
                                                    selectedList = "Prospects"
                                                    searchText = ""
                                                    onSave()
                                                },
                                                onDismiss: {
                                                    suggestedProspect = nil
                                                }
                                            )
                                            .animation(.easeInOut(duration: 0.25), value: suggestedProspect)
                                        }
                        
                    }
                    .animation(.easeInOut(duration: 0.3), value: suggestedProspect)
                    .padding(.horizontal, 20)

                    // Contacts table card
                    ContactsContainerView(selectedList: $selectedList, searchText: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    
                }
                

                // Dim background if menu is open
                if showAddOptionsMenu {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation { showAddOptionsMenu = false }
                        }
                }

                // The + toolbar
                ContactsToolbarView(
                    searchText: $searchText,
                    isSearchExpanded: $isSearchExpanded,
                    isSearchFocused: $isSearchFocused,
                    onAddTapped: {
                        if selectedList == "Prospects" {
                            withAnimation(.spring()) {
                                showAddOptionsMenu = true
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
                        .contentShape(Rectangle()) // make it tappable (optional)
                    }
                }
            )
            .overlay(addProspectOverlay)
            .overlay(addCustomerOverlay)
            .overlay(
                Group {
                    if showAddOptionsMenu {
                        VStack {
                            Spacer()
                            HStack {
                                AddProspectOptionsMenu(
                                    onAddManually: {
                                        withAnimation { showAddOptionsMenu = false }
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
            .onChange(of: selectedList) { newValue in
                if newValue == "Prospects" {
                    Task {
                        await fetchNextSuggestedNeighbor()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var addProspectOverlay: some View {
        if showingAddProspect {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { showingAddProspect = false }

            ProspectCreateStepperView { newProspect in
                modelContext.insert(newProspect)
                try? modelContext.save()
                selectedList = "Prospects"
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
            .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY * 0.9)
            .transition(.scale.combined(with: .opacity))
            .zIndex(2000)
        }
    }

    @ViewBuilder
    private var addCustomerOverlay: some View {
        
        if showingAddCustomer {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { showingAddCustomer = false }

            CustomerCreateStepperView { newCustomer in
                Task {
                    let p = Prospect(fullName: newCustomer.fullName,
                                     address: newCustomer.address,
                                     count: 0,
                                     list: "Customers")
                    p.contactEmail = newCustomer.contactEmail
                    p.contactPhone = newCustomer.contactPhone
                    
                    modelContext.insert(p)
                    try? modelContext.save()
                    
                    selectedList = "Customers"
                    searchText = ""
                    showingAddCustomer = false
                    await fetchNextSuggestedNeighbor()
                    onSave()
                }
            } onCancel: {
                showingAddCustomer = false
            }
            .frame(width: 300, height: 300)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 8)
            .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY * 0.9)
            .transition(.scale.combined(with: .opacity))
            .zIndex(2000)
        }
    }
    
    @ViewBuilder
    private func toggleChip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout)                 // ↑ from .caption
                .fontWeight(.semibold)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .frame(minWidth: 110)           // a bit wider
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isOn ? Color.blue : Color(.secondarySystemBackground))
                )
                .foregroundColor(isOn ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isOn ? Color.blue.opacity(0.9) : Color.gray.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }

    private func formatPhoneNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        if digits.count == 10 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        } else {
            return raw
        }
    }

    func fetchSuggestedNeighbor(from customer: Prospect) async {
        let controller = DatabaseController.shared

        let neighbor = await withCheckedContinuation { (continuation: CheckedContinuation<Prospect?, Never>) in
            controller.geocodeAndSuggestNeighbor(from: customer.address) { address in
                if let addr = address {
                    let suggested = Prospect(fullName: "Suggested Neighbor", address: addr, count: 0, list: "Prospects")
                    continuation.resume(returning: suggested)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }

        if let neighbor = neighbor {
            suggestedProspect = neighbor
        }
    }
    
    func fetchNextSuggestedNeighbor() async {
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
                    // NEW: Check SwiftData for duplicates
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

struct AddProspectOptionsMenu: View {
    let onAddManually: () -> Void
    let onImportFromContacts: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                onAddManually()
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Add Manually")
                }
                .padding()
            }
            .buttonStyle(.borderedProminent)

            Button {
                onImportFromContacts()
            } label: {
                HStack {
                    Image(systemName: "person.icloud") // icon for import
                    Text("Import From iPhone")
                }
                .padding()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 6)
        // position it near the + button
        .frame(maxWidth: 200)
    }
}
