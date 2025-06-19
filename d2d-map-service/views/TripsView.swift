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
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(trips, id: \.persistentModelID) { trip in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(trip.date.formatted(.dateTime.month().day().year()))
                                .font(.caption)
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 6) {
                                Label(trip.startAddress, systemImage: "circle.fill")
                                Label(trip.endAddress, systemImage: "mappin.circle.fill")
                                HStack {
                                    Image(systemName: "car.fill")
                                        .foregroundColor(.blue)
                                    Text("\(trip.miles, specifier: "%.1f") miles")
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 1)
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

                    // Add Trip Button Section
                    VStack {
                        Button {
                            showingAddTrip = true
                        } label: {
                            Label("Add Trip", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding(.top, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
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
