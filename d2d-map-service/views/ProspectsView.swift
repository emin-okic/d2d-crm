//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI

struct ProspectsView: View {
    @Binding var prospects: [Prospect]
    
    // Instead of having its own `@State selectedList`, we accept a `Binding<String>`
    @Binding var selectedList: String
    
    // A simple callback to let RootView know “Done saving”
    var onSave: () -> Void

    @State private var selectedProspectID: UUID?
    @State private var showingAddProspect = false

    // The two lists we support:
    let availableLists = ["Prospects", "Customers"]

    var body: some View {
        NavigationView {
            List {
                // Section for the "table header"-style list filter
                Section {
                    Picker("Select List", selection: $selectedList) {
                        ForEach(availableLists, id: \.self) { listName in
                            Text(listName)
                        }
                    }
                    .pickerStyle(.segmented) // Use segmented style for header-like appearance
                    .padding(.vertical, 4)
                }
                
                // Filter by the single shared `selectedList`
                let filteredProspects = selectedList == "All"
                    ? prospects
                    : prospects.filter { $0.list == selectedList }

                ForEach(filteredProspects, id: \.id) { prospect in
                    Button {
                        selectedProspectID = prospect.id
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
                            destination: EditProspectView(prospect: binding(for: prospect.id)),
                            tag: prospect.id,
                            selection: $selectedProspectID
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    )
                }
            }
            .navigationTitle(selectedList)
            .toolbar {

                // Right side: a “+” button to show the NewProspectView sheet
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddProspect = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProspect) {
                // Pass along the same `selectedList` binding
                NewProspectView(
                    prospects: $prospects,
                    selectedList: $selectedList
                ) {
                    showingAddProspect = false
                    onSave()
                }
            }
        }
    }

    private func binding(for id: UUID) -> Binding<Prospect> {
        guard let index = prospects.firstIndex(where: { $0.id == id }) else {
            fatalError("Prospect not found")
        }
        return $prospects[index]
    }
}
