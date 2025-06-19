//
//  NewTripView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//
import SwiftUI
import SwiftData

struct NewTripView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let userEmail: String
    var onSave: () -> Void

    @State private var startAddress = ""
    @State private var endAddress = ""
    @State private var miles = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Start Address", text: $startAddress)
                TextField("End Address", text: $endAddress)

                Button("Save Trip") {
                    guard !startAddress.isEmpty && !endAddress.isEmpty else { return }

                    Task {
                        let distance = await TripsController.shared.calculateMiles(from: startAddress, to: endAddress)
                        print("🧭 Calculated distance: \(distance)")

                        guard !distance.isNaN else {
                            print("❌ Invalid distance. Trip not saved.")
                            return
                        }

                        let trip = Trip(userEmail: userEmail, startAddress: startAddress, endAddress: endAddress, miles: distance)

                        await MainActor.run {
                            context.insert(trip)
                            try? context.save()
                            onSave()
                            dismiss()
                        }
                    }
                }
                .disabled(startAddress.isEmpty || endAddress.isEmpty)
            }
            .navigationTitle("New Trip")
        }
    }
}
