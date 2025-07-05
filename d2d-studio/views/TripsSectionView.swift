//
//  TripsSectionView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//


import SwiftUI
import SwiftData

struct TripsSectionView: View {
    @Query private var allTrips: [Trip]
    @State private var filter: TripFilter = .week
    @State private var selectedTrip: Trip?
    @State private var showingAddTrip = false

    private var filteredTrips: [Trip] {
        let calendar = Calendar.current
        let now = Date()

        return allTrips.filter { trip in
            switch filter {
            case .day:
                return calendar.isDate(trip.date, inSameDayAs: now)
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return trip.date >= weekAgo
            case .month:
                guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
                return trip.date >= monthAgo
            case .year:
                guard let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) else { return false }
                return trip.date >= yearAgo
            }
        }
        .sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trips")
                    .font(.headline)
                Spacer()
                Menu {
                    Picker("Filter", selection: $filter) {
                        ForEach(TripFilter.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                }
                Button {
                    showingAddTrip = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)

            if filteredTrips.isEmpty {
                Text("No trips logged yet.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                List(filteredTrips) { trip in
                    Button {
                        selectedTrip = trip
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.date.formatted(date: .abbreviated, time: .shortened))
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
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showingAddTrip) {
            NewTripView { showingAddTrip = false }
        }
        .sheet(item: $selectedTrip) { trip in
            EditTripView(trip: trip)
        }
    }
}
