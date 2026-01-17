//
//  NewTripView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//
import SwiftUI
import SwiftData
import MapKit

struct NewTripView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    var onSave: () -> Void

    @State private var startAddress = ""
    @State private var endAddress = ""
    @State private var tripDate = Date()
    
    @StateObject private var searchVM = SearchCompleterViewModel()
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Start Address
                    AddressInputField(
                        title: "Start Address",
                        text: $startAddress,
                        focusedField: $focusedField,
                        field: .start,
                        searchVM: searchVM
                    )

                    // MARK: - End Address
                    AddressInputField(
                        title: "End Address",
                        text: $endAddress,
                        focusedField: $focusedField,
                        field: .end,
                        searchVM: searchVM
                    )
                    
                    // MARK: - Trip Date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trip Date & Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        DatePicker("Select Date & Time", selection: $tripDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // MARK: - Save Button
                    Button {
                        
                        TripManagerHapticsController.shared.successConfirmationTap()
                        TripManagerSoundController.shared.playSound1()
                        
                        saveTrip()
                        
                    } label: {
                        Text("Save Trip")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(startAddress.isEmpty || endAddress.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(12)
                    }
                    .disabled(startAddress.isEmpty || endAddress.isEmpty)
                    
                }
                .padding()
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func saveTrip() {
        guard !startAddress.isEmpty && !endAddress.isEmpty else { return }
        Task {
            let distance = await TripsController.shared.calculateMiles(from: startAddress, to: endAddress)
            let trip = Trip(startAddress: startAddress, endAddress: endAddress, miles: distance, date: tripDate)
            await MainActor.run {
                context.insert(trip)
                try? context.save()
                onSave()
                dismiss()
            }
        }
    }
}

enum Field {
    case start, end
}
