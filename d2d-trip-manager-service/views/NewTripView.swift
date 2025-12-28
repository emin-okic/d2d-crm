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
    @State private var miles = ""
    
    @State private var tripDate = Date()
    
    @StateObject private var searchVM = SearchCompleterViewModel()
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Start Address", text: $startAddress)
                            .focused($focusedField, equals: .start)
                            .onChange(of: startAddress) { searchVM.updateQuery($0) }

                        if focusedField == .start && !searchVM.results.isEmpty {
                            
                            ForEach(searchVM.results.prefix(3), id: \.self) { result in
                                Button {
                                    SearchBarController.resolveAndSelectAddress(from: result) { resolved in
                                        startAddress = resolved
                                        searchVM.results = []
                                        focusedField = nil
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(result.title).bold()
                                        Text(result.subtitle).font(.subheadline).foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("End Address", text: $endAddress)
                            .focused($focusedField, equals: .end)
                            .onChange(of: endAddress) { searchVM.updateQuery($0) }

                        if focusedField == .end && !searchVM.results.isEmpty {
                            
                            ForEach(searchVM.results.prefix(3), id: \.self) { result in
                                Button {
                                    SearchBarController.resolveAndSelectAddress(from: result) { resolved in
                                        endAddress = resolved
                                        searchVM.results = []
                                        focusedField = nil
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(result.title).bold()
                                        Text(result.subtitle).font(.subheadline).foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            
                        }
                    }
                    
                    // Trip Date / Time Picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trip Date & Time").font(.footnote).foregroundColor(.secondary)
                        DatePicker("Select Date & Time", selection: $tripDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                }

                Button("Save Trip") {
                    guard !startAddress.isEmpty && !endAddress.isEmpty else { return }
                    
                    Task {
                        let distance = await TripsController.shared.calculateMiles(from: startAddress, to: endAddress)
                        print("🧭 Calculated distance: \(distance)")

                        guard !distance.isNaN else {
                            print("❌ Invalid distance. Trip not saved.")
                            return
                        }

                        let trip = Trip(
                            startAddress: startAddress,
                            endAddress: endAddress,
                            miles: distance,
                            date: tripDate
                        )

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

enum Field {
    case start, end
}
