//
//  TripsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//
import SwiftUI
import SwiftData

enum TripFilter: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { self.rawValue }
}

struct TripsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTripID: PersistentIdentifier?
    @State private var showingAddTrip = false
    @State private var filter: TripFilter = .day

    @Query private var allTrips: [Trip]

    // MARK: - Date Filtering
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
        .sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Spacer()
                    // MARK: - Custom Header
                    HStack {
                        Text("Activity")
                            .font(.title)
                            .fontWeight(.bold)

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
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // MARK: - Trip Cards
                    ForEach(filteredTrips, id: \.persistentModelID) { trip in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(trip.date.formatted(.dateTime
                                .month(.wide)
                                .day(.defaultDigits)
                                .year()
                                .hour(.defaultDigits(amPM: .wide))
                                .minute()))
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
                    .padding(.top, 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("") // Hide default title
            .sheet(isPresented: $showingAddTrip) {
                NewTripView {
                    showingAddTrip = false
                }
            }
        }
    }
}
