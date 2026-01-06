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
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start Address")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            
                            VStack(spacing: 0) {
                                TextField("Enter start address", text: $startAddress)
                                    .focused($focusedField, equals: .start)
                                    .padding(12)
                                    .onChange(of: startAddress) { searchVM.updateQuery($0) }
                                
                                if focusedField == .start && !searchVM.results.isEmpty {
                                    VStack(spacing: 0) {
                                        ForEach(searchVM.results.prefix(3), id: \.self) { result in
                                            Button {
                                                SearchBarController.resolveAndSelectAddress(from: result) { resolved in
                                                    startAddress = resolved
                                                    searchVM.results = []
                                                    focusedField = nil
                                                }
                                            } label: {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.title).bold()
                                                    Text(result.subtitle)
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color(.systemBackground))
                                            }
                                            Divider()
                                        }
                                    }
                                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                }
                            }
                        }
                    }

                    // MARK: - End Address
                    VStack(alignment: .leading, spacing: 6) {
                        Text("End Address")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            
                            VStack(spacing: 0) {
                                TextField("Enter end address", text: $endAddress)
                                    .focused($focusedField, equals: .end)
                                    .padding(12)
                                    .onChange(of: endAddress) { searchVM.updateQuery($0) }
                                
                                if focusedField == .end && !searchVM.results.isEmpty {
                                    VStack(spacing: 0) {
                                        ForEach(searchVM.results.prefix(3), id: \.self) { result in
                                            Button {
                                                SearchBarController.resolveAndSelectAddress(from: result) { resolved in
                                                    endAddress = resolved
                                                    searchVM.results = []
                                                    focusedField = nil
                                                }
                                            } label: {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.title).bold()
                                                    Text(result.subtitle)
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color(.systemBackground))
                                            }
                                            Divider()
                                        }
                                    }
                                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                }
                            }
                        }
                    }

                    // MARK: - Trip Date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trip Date & Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        DatePicker("Select Date & Time", selection: $tripDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // MARK: - Save Button
                    Button {
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
