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
    /// Access to the model context for database operations.
    @Environment(\.modelContext) private var modelContext
    
    /// The currently selected list filter (e.g., "Prospects" or "Customers").
    @Binding var selectedList: String
    
    /// Closure to call when a new prospect is added or changes are saved.
    var onSave: () -> Void
    
    /// Email of the current user, used to filter prospects.
    var userEmail: String
    
    /// Stores the ID of the selected prospect to support navigation.
    @State private var selectedProspectID: PersistentIdentifier?
    
    /// Controls whether the "New Prospect" sheet is shown.
    @State private var showingAddProspect = false
    
    /// The available list types to filter prospects by.
    let availableLists = ["Prospects", "Customers"]
    
    /// A query that fetches all prospects owned by the current user.
    @Query var prospects: [Prospect]
    
    /// Custom initializer that injects dynamic user-specific filtering into the query.
    init(selectedList: Binding<String>, userEmail: String, onSave: @escaping () -> Void) {
        _selectedList = selectedList
        self.userEmail = userEmail
        self.onSave = onSave
        
        // Only fetch prospects created by the current user
        _prospects = Query(filter: #Predicate<Prospect> { $0.userEmail == userEmail })
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                
                // Floating dropdown button (change list)
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
                .padding(.bottom, 12)
                .padding(.trailing, 16)
                .navigationTitle("Your \(selectedList)")
                
                // Main list view
                List {
                    
                    // Add a transparent spacer section to push records down into the safe zone
                    Section {
                        EmptyView()
                        EmptyView()
                    }
                    .frame(height: 60) // Adjust spacing here
                    .listRowInsets(EdgeInsets()) // Prevent padding around the spacer
                    .listRowSeparator(.hidden) // Hide any separator line
                    
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
                }
                .padding(.top, 60) // Add this to push content below the floating menu
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
            }
        }
    }
    
    private func formatPhoneNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        
        if digits.count == 10 {
            let area = digits.prefix(3)
            let middle = digits.dropFirst(3).prefix(3)
            let last = digits.suffix(4)
            return "\(area)-\(middle)-\(last)"
        } else {
            return raw // fallback for incomplete/invalid numbers
        }
    }
}
