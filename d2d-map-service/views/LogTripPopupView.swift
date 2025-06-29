//
//  LogTripPopupView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//


import SwiftUI
import SwiftData

struct LogTripPopupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var startAddress: String = ""
    @State private var endAddress: String
    @State private var date: Date = .now

    init(endAddress: String) {
        _endAddress = State(initialValue: endAddress)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Start Address", text: $startAddress)
                    TextField("End Address", text: $endAddress)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section {
                    Button("Log Trip") {
                        Task {
                            let miles = await TripDistanceHelper.calculateMiles(from: startAddress, to: endAddress)
                            let trip = Trip(startAddress: startAddress, endAddress: endAddress, miles: miles, date: date)
                            modelContext.insert(trip)
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                    .disabled(startAddress.isEmpty || endAddress.isEmpty)
                }
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
