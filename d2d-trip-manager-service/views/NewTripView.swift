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
    
    let onSave: () -> Void
    let onSkip: (() -> Void)?

    @State private var startAddress: String
    @State private var endAddress: String
    @State private var tripDate = Date()
    @State private var isSaving = false
    
    @StateObject private var searchVM = SearchCompleterViewModel()
    @FocusState private var focusedField: Field?

    init(
        initialStartAddress: String = "",
        initialEndAddress: String = "",
        onSkip: (() -> Void)? = nil,
        onSave: @escaping () -> Void
    ) {
        _startAddress = State(initialValue: initialStartAddress)
        _endAddress = State(initialValue: initialEndAddress)
        self.onSkip = onSkip
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Record mileage for this appointment")
                            .font(.subheadline.weight(.semibold))

                        Text("Add your route, or skip if there is no mileage.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
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
                    HStack(spacing: 12) {
                        Label("Trip Date", systemImage: "calendar")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 0)

                        DatePicker(
                            "Trip Date",
                            selection: $tripDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    
                    // MARK: - Save Button
                    Button {
                        
                        TripManagerHapticsController.shared.successConfirmationTap()
                        TripManagerSoundController.shared.playSound1()
                        
                        saveTrip()
                        
                    } label: {
                        Label(isSaving ? "Calculating Mileage" : "Save Trip", systemImage: isSaving ? "car" : "checkmark")
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(startAddress.isEmpty || endAddress.isEmpty || isSaving ? Color.gray.opacity(0.3) : Color.blue)
                            .foregroundColor(.white)
                            .font(.headline)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(startAddress.isEmpty || endAddress.isEmpty || isSaving)
                    
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Record Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onSkip {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Skip") {
                            TripManagerHapticsController.shared.lightTap()
                            TripManagerSoundController.shared.playSound1()
                            onSkip()
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func saveTrip() {
        let trimmedStartAddress = startAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEndAddress = endAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedStartAddress.isEmpty == false, trimmedEndAddress.isEmpty == false else { return }

        isSaving = true
        Task {
            let distance = await TripsController.shared.calculateMiles(
                from: trimmedStartAddress,
                to: trimmedEndAddress
            )
            let trip = Trip(
                startAddress: trimmedStartAddress,
                endAddress: trimmedEndAddress,
                miles: distance,
                date: tripDate
            )
            context.insert(trip)
            try? context.save()
            isSaving = false
            onSave()
            dismiss()
        }
    }
}

enum Field {
    case start, end
}
