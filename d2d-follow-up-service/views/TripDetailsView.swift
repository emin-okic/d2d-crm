//
//  TripDetailsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//
import SwiftUI
import SwiftData

struct TripDetailsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var trip: Trip

    @State private var startAddress: String
    @State private var endAddress: String
    @State private var miles: String
    @State private var date: Date

    init(trip: Trip) {
        self.trip = trip
        _startAddress = State(initialValue: trip.startAddress)
        _endAddress = State(initialValue: trip.endAddress)
        _miles = State(initialValue: String(format: "%.1f", trip.miles))
        _date = State(initialValue: trip.date)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General Trip Details")) {
                    
                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(.blue)
                        TextField("Start Address", text: $startAddress)
                            .autocapitalization(.words)
                    }

                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        TextField("End Address", text: $endAddress)
                            .autocapitalization(.words)
                    }
                    
                    // Prettified date picker bar
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        DatePicker("Trip Date", selection: $date, displayedComponents: [.date])
                            .labelsHidden()
                    }
                }
                
                Section(header: Text("Route Details")) {
                    RouteMapView(startAddress: startAddress, endAddress: endAddress)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.vertical, 8)
                }

                Section {
                    Button("Save Changes") {
                        Task {
                            let distance = await TripsController.shared.calculateMiles(from: startAddress, to: endAddress)

                            await MainActor.run {
                                trip.startAddress = startAddress
                                trip.endAddress = endAddress
                                trip.miles = distance
                                trip.date = date
                                try? context.save()
                                dismiss()
                            }
                        }
                    }

                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Trip Details")
        }
    }
}
