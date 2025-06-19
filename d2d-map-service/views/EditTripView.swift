//
//  EditTripView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//

import SwiftUI
import SwiftData

struct EditTripView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var trip: Trip

    @State private var startAddress: String
    @State private var endAddress: String
    @State private var miles: String

    init(trip: Trip) {
        self.trip = trip
        _startAddress = State(initialValue: trip.startAddress)
        _endAddress = State(initialValue: trip.endAddress)
        _miles = State(initialValue: String(format: "%.1f", trip.miles))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Start Address", text: $startAddress)
                    TextField("End Address", text: $endAddress)
                    TextField("Miles", text: $miles)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Button("Save Changes") {
                        if let milesDouble = Double(miles) {
                            trip.startAddress = startAddress
                            trip.endAddress = endAddress
                            trip.miles = milesDouble
                            try? context.save()
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Trip")
        }
    }
}
