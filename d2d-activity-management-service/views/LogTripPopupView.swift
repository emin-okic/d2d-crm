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
    @FocusState private var focusedField: Field?

    init(endAddress: String) {
        _endAddress = State(initialValue: endAddress)
    }

    var body: some View {
        NavigationView {
            Form {
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
                        DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                }

                Section {
                    LogTripButtonView(
                        startAddress: startAddress,
                        endAddress: endAddress,
                        date: date,
                        onComplete: { dismiss() }
                    )
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
