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
    @State private var selectedList: String = "Prospects"

    let availableLists = ["Prospects", "Customers"]

    var body: some View {
        NavigationView {
            List {
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
                            Text(prospect.list)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filter", selection: $selectedList) {
                            ForEach(availableLists, id: \.self) { list in
                                Text(list)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }

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

    private func binding(for id: UUID) -> Binding<Prospect> {
        guard let index = prospects.firstIndex(where: { $0.id == id }) else {
            fatalError("Prospect not found")
        }
        return $prospects[index]
    }
}

