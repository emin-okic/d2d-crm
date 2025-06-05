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
    @Query var prospects: [Prospect]

    @Binding var selectedList: String
    var onSave: () -> Void

    @State private var selectedProspectID: PersistentIdentifier?
    @State private var showingAddProspect = false

    let availableLists = ["Prospects", "Customers"]

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
                NewProspectView(selectedList: $selectedList) {
                    showingAddProspect = false
                    onSave()
                }
            }
        }
    }
}
