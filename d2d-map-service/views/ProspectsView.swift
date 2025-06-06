//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData

struct ProspectsView: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var selectedList: String
    var onSave: () -> Void
    var userEmail: String

    @State private var selectedProspectID: PersistentIdentifier?
    @State private var showingAddProspect = false

    let availableLists = ["Prospects", "Customers"]

    @Query var prospects: [Prospect]

    // ✅ Custom initializer
    init(selectedList: Binding<String>, userEmail: String, onSave: @escaping () -> Void) {
        _selectedList = selectedList
        self.userEmail = userEmail
        self.onSave = onSave

        // ✅ Inject predicate using runtime value
        _prospects = Query(filter: #Predicate<Prospect> { $0.userEmail == userEmail })
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker("Select List", selection: $selectedList) {
                        ForEach(availableLists, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }

                let filteredProspects = selectedList == "All"
                    ? prospects
                    : prospects.filter { $0.list == selectedList }

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
            .navigationTitle(selectedList)
            .toolbar {
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
