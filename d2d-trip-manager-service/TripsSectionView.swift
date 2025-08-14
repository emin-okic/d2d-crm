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
        ZStack {
            // CONTENT pinned to top-left
            VStack(alignment: .leading, spacing: 12) {

                // Filter chips (Day / Week / Month / Year)
                HStack(spacing: 8) {
                    ForEach(TripFilter.allCases) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                filter = option
                            }
                        } label: {
                            Text(option.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(filter == option ? Color.blue : Color(.secondarySystemBackground))
                                )
                                .foregroundColor(filter == option ? .white : .primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(filter == option ? Color.blue.opacity(0.9) : Color.gray.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)

                if filteredTrips.isEmpty {
                    Text("No trips logged yet.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
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
                    .padding(.top, 4)
                }

                Spacer(minLength: 0) // keep content stuck to the top even when empty
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Bottom-left floating "+" (matches your other screens)
            VStack(spacing: 10) {
                Button {
                    showingAddTrip = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }
            }
            .padding(.bottom, 30)
            .padding(.leading, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .zIndex(999)
        }
        .sheet(isPresented: $showingAddTrip) {
            NewTripView { showingAddTrip = false }
        }
        .sheet(item: $selectedTrip) { trip in
            TripDetailsView(trip: trip)
        }
    }
}
