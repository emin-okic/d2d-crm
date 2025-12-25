//
//  ProspectCreateStepperView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/26/25.
//

import SwiftUI
import MapKit
import PhoneNumberKit

struct ProspectCreateStepperView: View {
    var onComplete: (Prospect) -> Void
    var onCancel: () -> Void

    @State private var stepIndex = 0
    private let totalSteps = 2

    @State private var fullName = ""
    @State private var address = ""
    @State private var contactPhone = ""
    @State private var contactEmail = ""

    @StateObject private var searchVM = SearchCompleterViewModel()
    @FocusState private var isAddressFocused: Bool
    @State private var phoneError: String?

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

            // Scrollable content
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

    // MARK: Header
    private var header: some View {
        HStack {
            Text("New Prospect")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .background(Circle().fill(Color.secondary.opacity(0.15)))
            }
        }
    }

    // MARK: Card Layout Helper
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

    // MARK: Step 1
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
                                        Text(result.title).fontWeight(.medium)
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

    // MARK: Step 2
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
            }
        }
    }

    // MARK: Labeled Field
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

    // MARK: Footer
    private var footerActions: some View {
        HStack {
            if stepIndex > 0 {
                Button("Back") { stepIndex = 0 }
            }

            Spacer()

            if stepIndex == 0 {
                Button("Next") { stepIndex = 1 }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceedStepOne)
            } else {
                Button("Finish") {
                    guard validatePhoneNumber() else { return }
                    createProspect()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceedStepTwo)
            }
        }
    }

    // MARK: Helpers
    private var canProceedStepOne: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canProceedStepTwo: Bool { phoneError == nil }

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
        do { _ = try utility.parse(raw); phoneError = nil; return true }
        catch { phoneError = "Invalid phone number."; return false }
    }

    private func createProspect() {
        let p = Prospect(fullName: fullName, address: address, count: 0, list: "Prospects")
        p.contactEmail = contactEmail
        p.contactPhone = contactPhone

        CLGeocoder().geocodeAddressString(address) { placemarks, _ in
            if let coord = placemarks?.first?.location?.coordinate {
                p.latitude = coord.latitude
                p.longitude = coord.longitude
            }
            DispatchQueue.main.async { onComplete(p) }
        }
    }
}
