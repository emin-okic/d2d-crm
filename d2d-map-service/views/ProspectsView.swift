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
                // Main list view
                List {
                    let filteredProspects = prospects.filter { $0.list == selectedList }

                    ForEach(filteredProspects, id: \.persistentModelID) { prospect in
                        Button {
                            selectedProspectID = prospect.persistentModelID
                        } label: {
                            VStack(alignment: .leading) {
                                Text(prospect.fullName)
                                Text(prospect.address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
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
                .toolbar {
                    // MARK: - Add Prospect Button
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showingAddProspect = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
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
}
