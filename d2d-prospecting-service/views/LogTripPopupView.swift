//
//  LogTripPopupView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//


import SwiftUI
import SwiftData

import Combine
import Contacts
import MapKit

struct LogTripPopupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var startAddress: String = ""
    @State private var endAddress: String
    @State private var date: Date = .now
    
    @StateObject private var searchVM = SearchCompleterViewModel()
    @FocusState private var isStartFocused: Bool

    init(endAddress: String) {
        _endAddress = State(initialValue: endAddress)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Start Address", text: $startAddress)
                            .focused($isStartFocused)
                            .onChange(of: startAddress) { newValue in
                                searchVM.updateQuery(newValue)
                            }

                        if isStartFocused && !searchVM.results.isEmpty {
                            ForEach(searchVM.results.prefix(3), id: \.self) { result in
                                Button {
                                    handleStartAddressSelection(result)
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
    
    private func handleStartAddressSelection(_ result: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: result)
        MKLocalSearch(request: request).start { response, error in
            guard let item = response?.mapItems.first else { return }

            DispatchQueue.main.async {
                startAddress = item.placemark.title ?? result.title
                searchVM.results = []
                isStartFocused = false
            }
        }
    }
    
}
