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
                TextField("Miles", text: $miles)
                    .keyboardType(.decimalPad)

                Button("Save Trip") {
                    if let milesDouble = Double(miles) {
                        let trip = Trip(userEmail: userEmail, startAddress: startAddress, endAddress: endAddress, miles: milesDouble)
                        context.insert(trip)
                        try? context.save()
                        onSave()
                        dismiss()
                    }
                }
            }
            .navigationTitle("New Trip")
        }
    }
}
