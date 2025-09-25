//
//  CustomerCreationController.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/25/25.
//

import Foundation
import SwiftUI
import MapKit
import PhoneNumberKit

@MainActor
class CustomerCreationController: ObservableObject {
    @Published var stepIndex: Int = 0
    @Published var fullName: String
    @Published var address: String
    @Published var contactPhone: String
    @Published var contactEmail: String
    @Published var phoneError: String?
    @Published var searchVM = SearchCompleterViewModel()

    private let totalSteps = 2
    var totalStepCount: Int { totalSteps }

    init(
        initialName: String? = nil,
        initialAddress: String? = nil,
        initialPhone: String? = nil,
        initialEmail: String? = nil
    ) {
        self.fullName = initialName ?? ""
        self.address = initialAddress ?? ""
        self.contactPhone = initialPhone ?? ""
        self.contactEmail = initialEmail ?? ""
    }

    // Navigation
    func nextStep() { if stepIndex < totalSteps - 1 { stepIndex += 1 } }
    func backStep() { if stepIndex > 0 { stepIndex -= 1 } }

    // Validation
    var canProceedStepOne: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canProceedStepTwo: Bool { phoneError == nil }

    @discardableResult
    func validatePhoneNumber() -> Bool {
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

    func handleAddressSelection(_ result: MKLocalSearchCompletion) {
        Task {
            if let resolved = await SearchBarController.resolveAddress(from: result) {
                address = resolved
                searchVM.results = []
            }
        }
    }

    func buildCustomer() -> Customer {
        let c = Customer(fullName: fullName, address: address)
        c.contactEmail = contactEmail
        c.contactPhone = contactPhone
        return c
    }
}
