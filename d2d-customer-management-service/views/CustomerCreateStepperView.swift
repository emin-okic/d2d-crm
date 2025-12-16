//
//  CustomerCreateStepperView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/17/25.
//

import SwiftUI
import SwiftData
import MapKit
import PhoneNumberKit

struct CustomerCreateStepperView: View {
    var onComplete: (Customer) -> Void
    var onCancel: () -> Void

    // 👇 New optional defaults
    var initialName: String?
    var initialAddress: String?
    var initialPhone: String?
    var initialEmail: String?

    @State private var stepIndex: Int = 0
    private let totalSteps = 2

    // 👇 Initialize state with passed-in values
    @State private var fullName: String
    @State private var address: String
    @State private var contactPhone: String
    @State private var contactEmail: String
    
    @StateObject private var searchVM = SearchCompleterViewModel()
    @FocusState private var isAddressFocused: Bool
    @State private var phoneError: String?

    init(
        initialName: String? = nil,
        initialAddress: String? = nil,
        initialPhone: String? = nil,
        initialEmail: String? = nil,
        onComplete: @escaping (Customer) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.initialName = initialName
        self.initialAddress = initialAddress
        self.initialPhone = initialPhone
        self.initialEmail = initialEmail

        _fullName = State(initialValue: initialName ?? "")
        _address = State(initialValue: initialAddress ?? "")
        _contactPhone = State(initialValue: initialPhone ?? "")
        _contactEmail = State(initialValue: initialEmail ?? "")
    }

    var body: some View {
        VStack(spacing: 8) {
            // header
            HStack {
                Text("New Customer")
                    .font(.headline)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            DotStepBar(total: totalSteps, index: stepIndex)

            // content
            Group {
                if stepIndex == 0 { stepOne }
                else { stepTwo }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                if stepIndex > 0 {
                    Button("Back") { stepIndex = 0 }
                }
                Spacer()
                if stepIndex == 0 {
                    Button("Next") { stepIndex = 1 }
                        .disabled(!canProceedStepOne)
                } else {
                    
                    Button("Finish") {
                        guard validatePhoneNumber() else { return }

                        Task {
                            let customer = Customer(fullName: fullName, address: address)
                            customer.contactEmail = contactEmail
                            customer.contactPhone = contactPhone

                            // 🔑 Resolve coordinates at creation time
                            if let coord = await geocodeAddress(address) {
                                customer.latitude = coord.latitude
                                customer.longitude = coord.longitude

                                print("""
                                📍 Customer created with coordinates
                                Address: \(address)
                                Lat: \(coord.latitude)
                                Lon: \(coord.longitude)
                                """)
                            } else {
                                print("⚠️ Customer created WITHOUT coordinates:", address)
                            }

                            await MainActor.run {
                                onComplete(customer)
                            }
                        }
                    }
                    .disabled(!canProceedStepTwo)
                }
            }
        }
        .padding(12)
    }

    // MARK: - Steps

    private var stepOne: some View {
        Form {
            Section(header: Text("Step 1 • Name & Address")) {
                TextField("Full Name", text: $fullName)

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Address", text: $address)
                        .focused($isAddressFocused)
                        .onChange(of: address) { searchVM.updateQuery($0) }

                    if isAddressFocused && !searchVM.results.isEmpty {
                        ForEach(searchVM.results.prefix(4), id: \.self) { result in
                            Button {
                                handleAddressSelection(result)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title).bold()
                                    Text(result.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
        }
    }

    private var stepTwo: some View {
        Form {
            Section(header: Text("Step 2 • Contact Details")) {
                TextField("Phone (Optional)", text: $contactPhone)
                    .keyboardType(.phonePad)
                    .onChange(of: contactPhone) { _ in _ = validatePhoneNumber() }

                if let phoneError = phoneError {
                    Text(phoneError).foregroundColor(.red).font(.caption)
                }

                TextField("Email (Optional)", text: $contactEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }

            // Extend “the rest” here later as needed
            // Section(header: Text("Other Details")) { ... }
        }
    }

    // MARK: - Helpers
    
    private func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address

        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.first?.placemark.coordinate
        } catch {
            print("❌ Geocoding failed:", error)
            return nil
        }
    }

    private var canProceedStepOne: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canProceedStepTwo: Bool {
        // Phone/email optional; only reject on explicit invalid phone
        phoneError == nil
    }

    private func handleAddressSelection(_ result: MKLocalSearchCompletion) {
        Task {
            if let resolved = await SearchBarController.resolveAddress(from: result) {
                address = resolved
                searchVM.results = []
                isAddressFocused = false
            }
        }
    }

    @discardableResult
    private func validatePhoneNumber() -> Bool {
        let raw = contactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { phoneError = nil; return true }

        let utility = PhoneNumberUtility()
        do {
            _ = try utility.parse(raw)
            phoneError = nil
            return true
        } catch {
            phoneError = "Invalid phone number."
            return false
        }
    }
}
