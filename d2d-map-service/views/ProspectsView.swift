//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI

struct ProspectsView: View {
    @Binding var prospects: [Prospect]
    @State private var selectedProspectID: UUID?
    @State private var showingAddProspect = false

    // Add these:
    @State private var selectedList: String = "All"
    let allLists = ["All", "Favorites", "To Contact", "Hot Leads"]
    
    var db = DatabaseController.shared

    var body: some View {
        NavigationView {
            VStack {
                Picker("List", selection: $selectedList) {
                    ForEach(allLists, id: \.self) { list in
                        Text(list)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedList) { newList in
                    prospects = db.getAllProspects(for: newList)
                }

                List {
                    ForEach($prospects, id: \.id) { $prospect in
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
                .navigationTitle("Prospects")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddProspect = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddProspect) {
                    NewProspectView(prospects: $prospects)
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
