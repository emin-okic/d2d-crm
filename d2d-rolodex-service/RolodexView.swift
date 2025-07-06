//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData

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
    @State private var suggestionSourceIndex = 0 // Track which customer we’re pulling from
    
    @State private var showActivityOnboarding = false

    let availableLists = ["Prospects", "Customers"]
    @Query var prospects: [Prospect]
    
    var onDoubleTap: ((Prospect) -> Void)? = nil

    init(
        selectedList: Binding<String>,
        onSave: @escaping () -> Void,
        onDoubleTap: ((Prospect) -> Void)? = nil
    ) {
        _selectedList = selectedList
        self.onSave = onSave
        self.onDoubleTap = onDoubleTap
        _prospects = Query()
    }
    
    private var totalProspects: Int {
        prospects.filter { $0.list == "Prospects" }.count
    }

    private var totalCustomers: Int {
        prospects.filter { $0.list == "Customers" }.count
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Custom Header
                HStack {
                    Text("The Rolodex")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Summary cards at the top
                HStack(spacing: 12) {
                    Button {
                        selectedList = "Prospects"
                    } label: {
                        SummaryCardView(title: "Total Prospects", count: totalProspects)
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedList = "Customers"
                    } label: {
                        SummaryCardView(title: "Total Customers", count: totalCustomers)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Title and list type selector
                HStack {
                    Text("Your \(selectedList)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

                // Main list of prospects
                // Main list of prospects
                List {
                    let filteredProspects = prospects.filter { $0.list == selectedList }

                    ForEach(filteredProspects, id: \.persistentModelID) { prospect in
                        ProspectRowView(
                            prospect: prospect,
                            onTap: {
                                selectedProspectID = prospect.persistentModelID
                            },
                            onDoubleTap: {
                                onDoubleTap?(prospect)
                            }
                        )
                        .background(
                            NavigationLink(
                                destination: EditProspectView(prospect: prospect),
                                tag: prospect.persistentModelID,
                                selection: $selectedProspectID
                            ) { EmptyView() }
                            .hidden()
                        )
                    }

                    if selectedList == "Prospects" {
                        Section {
                            Button {
                                showingAddProspect = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Prospect")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(10)
                    }

                    if selectedList == "Prospects", let suggestion = suggestedProspect {
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Suggested Neighbor")
                                    .font(.headline)

                                VStack(alignment: .leading, spacing: 4) {
                                    Label(suggestion.fullName, systemImage: "person.fill")
                                    Label(suggestion.address, systemImage: "mappin.and.ellipse")
                                }
                                .foregroundStyle(.secondary)

                                Button {
                                    modelContext.insert(suggestion)
                                    suggestedProspect = nil
                                    onSave()

                                    Task {
                                        await fetchNextSuggestedNeighbor()
                                    }
                                } label: {
                                    Label("Add This Prospect", systemImage: "plus.circle.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .listStyle(.plain)
                .padding(.top, 8) // <-- this is to separate from the header area
                
            }
            .navigationTitle("")
            .sheet(isPresented: $showingAddProspect) {
                NewProspectView(
                    selectedList: $selectedList,
                    onSave: {
                        showingAddProspect = false
                        onSave()
                    }
                )
            }
            .task {
                if selectedList == "Prospects", suggestedProspect == nil {
                    await fetchNextSuggestedNeighbor()
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: {
                showActivityOnboarding = true
            }) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 22))
                    .padding(14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 30)
        }
        .fullScreenCover(isPresented: $showActivityOnboarding) {
            ActivityOnboardingFlowView(isPresented: $showActivityOnboarding)
        }
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
