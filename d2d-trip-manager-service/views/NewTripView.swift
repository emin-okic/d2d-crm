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
                                    handleSelection(result, for: .start)
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
                                    handleSelection(result, for: .end)
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

                        let trip = Trip(startAddress: startAddress, endAddress: endAddress, miles: distance)

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
    
    private func handleSelection(_ result: MKLocalSearchCompletion, for field: Field) {
        let request = MKLocalSearch.Request(completion: result)
        MKLocalSearch(request: request).start { response, error in
            guard let item = response?.mapItems.first else { return }

            DispatchQueue.main.async {
                let selectedAddress = item.placemark.title ?? result.title
                switch field {
                case .start:
                    startAddress = selectedAddress
                case .end:
                    endAddress = selectedAddress
                }
                searchVM.results = []
                focusedField = nil
            }
        }
    }
}

enum Field {
    case start, end
}
