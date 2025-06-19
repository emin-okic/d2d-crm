//
//  TripsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//

import SwiftUI
import SwiftData

struct TripsView: View {
    @Environment(\.modelContext) private var modelContext
    let userEmail: String
    @State private var selectedTripID: PersistentIdentifier?
    @State private var showingAddTrip = false
    @Query var trips: [Trip]

    init(userEmail: String) {
        self.userEmail = userEmail
        _trips = Query(filter: #Predicate<Trip> { $0.userEmail == userEmail })
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(trips, id: \.persistentModelID) { trip in
                    VStack(alignment: .leading) {
                        Text("Trip ID: \(trip.id.uuidString.prefix(8))")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("📍 \(trip.startAddress) → \(trip.endAddress)")
                        Text("🛣️ \(trip.miles, specifier: "%.1f") miles")
                        Text("📅 \(trip.date.formatted(.dateTime.month().day().year()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTripID = trip.persistentModelID
                    }
                    .background(
                        NavigationLink(
                            destination: EditTripView(trip: trip),
                            tag: trip.persistentModelID,
                            selection: $selectedTripID
                        ) { EmptyView() }
                        .hidden()
                    )
                }

                Button {
                    showingAddTrip = true
                } label: {
                    Label("Add Trip", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }
            .navigationTitle("Activity")
            .sheet(isPresented: $showingAddTrip) {
                NewTripView(userEmail: userEmail) {
                    showingAddTrip = false
                }
            }
        }
    }
}
