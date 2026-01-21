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
    
    @State private var emailError: String?

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
        VStack(spacing: 0) {

            // Header
            header
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            DotStepBar(total: totalSteps, index: stepIndex)
                .padding(.bottom, 12)

            Divider()

            // Content
            ScrollView {
                LazyVStack(spacing: 16) {
                    if stepIndex == 0 {
                        stepOneCard
                    } else {
                        stepTwoCard
                    }
                }
                .padding()
            }

            Divider()

            // Footer actions
            footerActions
                .padding()
                .background(.ultraThinMaterial)
        }
    }
    
    private var header: some View {
        HStack {
            Text("New Customer")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()
            
            Button(action: {
                
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                
                onCancel()
                
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .background(Circle().fill(Color.secondary.opacity(0.15)))
            }
        }
    }
    
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
    }
    
    private var stepOneCard: some View {
        card {
            Text("Name & Address")
                .font(.headline)

            labeledField("Full Name") {
                TextField("John Smith", text: $fullName)
            }

            labeledField("Address") {
                VStack(spacing: 6) {
                    TextField("123 Main St", text: $address)
                        .focused($isAddressFocused)
                        .onChange(of: address) { searchVM.updateQuery($0) }

                    if isAddressFocused && !searchVM.results.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(searchVM.results.prefix(4), id: \.self) { result in
                                Button {
                                    handleAddressSelection(result)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title)
                                            .fontWeight(.medium)
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                Divider()
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 6)
                        )
                    }
                }
            }
        }
    }
    
    private var stepTwoCard: some View {
        card {
            Text("Contact Details")
                .font(.headline)

            labeledField("Phone (Optional)") {
                TextField("555-123-4567", text: $contactPhone)
                    .keyboardType(.phonePad)
                    .onChange(of: contactPhone) { _ in _ = validatePhoneNumber() }
            }

            if let phoneError = phoneError {
                Text(phoneError)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            labeledField("Email (Optional)") {
                TextField("name@email.com", text: $contactEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .onChange(of: contactEmail) { _ in _ = validateEmail() }
            }

            if let emailError = emailError {
                Text(emailError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func labeledField<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            content()
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                )
        }
    }
    
    private var footerActions: some View {
        HStack {
            if stepIndex > 0 {
                Button("Back") {
                    
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    stepIndex = 0
                    
                }
            }

            Spacer()

            if stepIndex == 0 {
                
                Button("Next") {
                    
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    stepIndex = 1
                    
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceedStepOne)
            } else {
                Button("Finish") {
                    
                    guard validatePhoneNumber(), validateEmail() else { return }
                    
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    createCustomer()
                    
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceedStepTwo)
            }
        }
    }
    
    private func createCustomer() {
        Task {
            let customer = Customer(fullName: fullName, address: address)
            customer.contactEmail = contactEmail
            customer.contactPhone = contactPhone

            if let coord = await geocodeAddress(address) {
                customer.latitude = coord.latitude
                customer.longitude = coord.longitude
            }

            await MainActor.run {
                onComplete(customer)
            }
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
        phoneError == nil && emailError == nil
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
    
    @discardableResult
    private func validateEmail() -> Bool {
        let raw = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            emailError = nil
            return true   // optional field
        }

        // Basic but effective pattern
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let isValid = raw.range(of: pattern, options: .regularExpression) != nil

        if isValid {
            emailError = nil
            return true
        } else {
            emailError = "Invalid email address."
            return false
        }
    }
}
