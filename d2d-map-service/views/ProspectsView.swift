//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData

/// A view that displays and manages a list of prospects associated with the logged-in user.
/// Users can filter by list type (e.g., "Prospects", "Customers"), add new prospects, and tap
/// a prospect to edit its details.
struct ProspectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedList: String
    var onSave: () -> Void
    var userEmail: String

    @State private var selectedProspectID: PersistentIdentifier?
    @State private var showingAddProspect = false
    @State private var suggestedProspect: Prospect?
    @State private var suggestionSourceIndex = 0 // Track which customer we’re pulling from

    let availableLists = ["Prospects", "Customers"]
    @Query var prospects: [Prospect]

    init(selectedList: Binding<String>, userEmail: String, onSave: @escaping () -> Void) {
        _selectedList = selectedList
        self.userEmail = userEmail
        self.onSave = onSave
        _prospects = Query(filter: #Predicate<Prospect> { $0.userEmail == userEmail })
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                Menu {
                    Button("Prospects") { selectedList = "Prospects" }
                    Button("Customers") { selectedList = "Customers" }
                } label: {
                    Text(selectedList)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                }
                .padding(.top, 12)
                .padding(.trailing, 16)
                .navigationTitle("Your \(selectedList)")

                List {
                    Section {
                        EmptyView()
                    }
                    .frame(height: 60)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)

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
                    }

                    let filteredProspects = prospects.filter { $0.list == selectedList }

                    ForEach(filteredProspects, id: \.persistentModelID) { prospect in
                        Button {
                            selectedProspectID = prospect.persistentModelID
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prospect.fullName)
                                    .font(.headline)
                                Text(prospect.address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                if !prospect.contactPhone.isEmpty {
                                    Text("📞 \(formatPhoneNumber(prospect.contactPhone))")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                if !prospect.contactEmail.isEmpty {
                                    Text("✉️ \(prospect.contactEmail)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .background(
                            NavigationLink(
                                destination: EditProspectView(prospect: prospect),
                                tag: prospect.persistentModelID,
                                selection: $selectedProspectID
                            ) { EmptyView() }
                            .hidden()
                        )
                    }

                    if selectedList == "Prospects", let suggestion = suggestedProspect {
                        Section {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(suggestion.fullName)
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    Text(suggestion.address)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Button("Add This Prospect") {
                                        modelContext.insert(suggestion)
                                        suggestedProspect = nil
                                        onSave()

                                        // Immediately pull the next suggestion from the next customer in the list
                                        Task {
                                            await fetchNextSuggestedNeighbor()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .padding(.top, 4)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 60)
                .sheet(isPresented: $showingAddProspect) {
                    NewProspectView(
                        selectedList: $selectedList,
                        onSave: {
                            showingAddProspect = false
                            onSave()
                        },
                        userEmail: userEmail
                    )
                }
                .task {
                    if selectedList == "Prospects", suggestedProspect == nil {
                        await fetchNextSuggestedNeighbor()
                    }
                }
            }
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
            controller.geocodeAndSuggestNeighbor(from: customer.address, for: userEmail) { address in
                if let addr = address {
                    let suggested = Prospect(fullName: "Suggested Neighbor", address: addr, count: 0, list: "Prospects", userEmail: userEmail)
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
                controller.geocodeAndSuggestNeighbor(from: customer.address, for: userEmail) { address in
                    // NEW: Check SwiftData for duplicates
                    if let addr = address,
                       !prospects.contains(where: { $0.address.caseInsensitiveCompare(addr) == .orderedSame }) {
                        let suggested = Prospect(
                            fullName: "Suggested Neighbor",
                            address: addr,
                            count: 0,
                            list: "Prospects",
                            userEmail: userEmail
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
