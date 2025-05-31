//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI

struct ProspectsView: View {
    @ObservedObject var store = ProspectsStore.shared

    @State private var selectedProspectID: UUID?
    @State private var showingAddProspect = false

    var body: some View {
        NavigationView {
            List {
                ForEach(store.prospects) { prospect in
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
                    Button {
                        showingAddProspect = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProspect) {
                NewProspectView() // updated to no longer need binding
            }
            .onAppear {
                store.loadProspects()
            }
        }
    }


    private func binding(for id: UUID) -> Binding<Prospect> {
        guard let index = store.prospects.firstIndex(where: { $0.id == id }) else {
            fatalError("Prospect not found")
        }
        return Binding(
            get: { store.prospects[index] },
            set: { store.prospects[index] = $0 }
        )
    }
}
