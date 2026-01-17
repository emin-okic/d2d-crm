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

    @FocusState private var focusedField: Field?
    @StateObject private var searchVM = SearchCompleterViewModel()

    @State private var showDeleteConfirmation = false

    // MARK: - Init
    init(trip: Trip) {
        self.trip = trip
        _startAddress = State(initialValue: trip.startAddress)
        _endAddress = State(initialValue: trip.endAddress)
        _miles = State(initialValue: String(format: "%.1f", trip.miles))
        _date = State(initialValue: trip.date)
    }

    // MARK: - Dirty check
    private var hasUnsavedEdits: Bool {
        startAddress.trimmingCharacters(in: .whitespacesAndNewlines) != trip.startAddress.trimmingCharacters(in: .whitespacesAndNewlines) ||
        endAddress.trimmingCharacters(in: .whitespacesAndNewlines) != trip.endAddress.trimmingCharacters(in: .whitespacesAndNewlines) ||
        date != trip.date
    }

    var body: some View {
        ZStack {
            NavigationStack {
                Form {
                    
                    RouteMapView(startAddress: startAddress, endAddress: endAddress)
                        .frame(height: 100)
                        .cornerRadius(12)
                        .padding(.vertical, 8)
                    
                    Section(header: Text("Trip Details")) {
                        TripAddressFieldView(
                            iconName: "circle",
                            placeholder: "Start Address",
                            iconColor: .blue,
                            addressText: $startAddress,
                            focusedField: $focusedField,
                            fieldType: .start,
                            searchVM: searchVM
                        )

                        TripAddressFieldView(
                            iconName: "mappin.circle.fill",
                            placeholder: "End Address",
                            iconColor: .red,
                            addressText: $endAddress,
                            focusedField: $focusedField,
                            fieldType: .end,
                            searchVM: searchVM
                        )

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            DatePicker("Trip Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                        }
                        
                    }
                }
                .navigationTitle("Trip Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Back button top-left
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            
                            // Haptics + sound
                            TripManagerHapticsController.shared.lightTap()
                            TripManagerSoundController.shared.playSound1()
                            
                            dismiss()
                            
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                    }

                    // Save button top-right (conditional)
                    if hasUnsavedEdits {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save Changes") {
                                Task {
                                    let distance = await TripsController.shared.calculateMiles(
                                        from: startAddress,
                                        to: endAddress
                                    )
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
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }

            // Floating circular trash button (bottom-left)
            VStack {
                Spacer()
                HStack {
                    Button(role: .destructive) {
                        
                        // Haptics + sound
                        TripManagerHapticsController.shared.lightTap()
                        TripManagerSoundController.shared.playSound1()
                        
                        showDeleteConfirmation = true
                        
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.red))
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 20)
                    .padding(.bottom, 30)

                    Spacer()
                }
            }
        }
        // Delete confirmation alert
        .alert("Delete Trip?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                
                // Haptics + sound for deletion
                TripManagerHapticsController.shared.mediumTap()
                TripManagerSoundController.shared.playSound1()
                
                context.delete(trip)
                
                try? context.save()
                
                dismiss()
                
            }
            Button("Cancel", role: .cancel) {
                
                // Haptics + sound for cancel
                TripManagerHapticsController.shared.lightTap()
                TripManagerSoundController.shared.playSound1()
                
            }
        } message: {
            Text("This trip will be permanently deleted.")
        }
    }
}
