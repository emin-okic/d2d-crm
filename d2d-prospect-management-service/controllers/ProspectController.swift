//
//  ProspectController.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import Foundation
import SwiftUI
import SwiftData
import PhoneNumberKit
import MapKit

@MainActor
class ProspectController: ObservableObject {
    @Published var tempPhone: String = ""
    @Published var tempEmail: String = ""
    @Published var phoneError: String?
    @Published var showConversionSheet = false
    @Published var showAppointmentSheet = false
    @Published var selectedAppointmentDetails: Appointment?
    @Published var selectedTab: ProspectTab = .appointments
    
    // Snapshot to detect edits
    private struct ProspectSnapshot: Equatable {
        var fullName: String
        var address: String
        var phone: String
        var email: String
        var list: String
    }
    
    private var baseline: ProspectSnapshot?
    
    func captureBaseline(from prospect: Prospect) {
        baseline = ProspectSnapshot(
            fullName: prospect.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            address: prospect.address.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: prospect.contactPhone.trimmingCharacters(in: .whitespacesAndNewlines),
            email: prospect.contactEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            list: prospect.list
        )
        tempPhone = prospect.contactPhone
        tempEmail = prospect.contactEmail
    }
    
    func isDirty(prospect: Prospect) -> Bool {
        guard let baseline else { return false }
        let current = ProspectSnapshot(
            fullName: prospect.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            address: prospect.address.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: prospect.contactPhone.trimmingCharacters(in: .whitespacesAndNewlines),
            email: prospect.contactEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            list: prospect.list
        )
        return current != baseline
    }
    
    func saveProspect(_ prospect: Prospect, modelContext: ModelContext) {
        try? modelContext.save()
        captureBaseline(from: prospect)
    }
    
    func convertToCustomer(_ prospect: Prospect, modelContext: ModelContext) {
        prospect.list = "Customers"
        prospect.contactPhone = tempPhone
        prospect.contactEmail = tempEmail
        try? modelContext.save()
    }
    
    func convertToCustomerFromDetailsScreen(_ prospect: Prospect, modelContext: ModelContext) -> Customer? {
        // Build new customer
        let customer = Customer(fullName: prospect.fullName, address: prospect.address)
        customer.contactPhone = tempPhone
        customer.contactEmail = tempEmail
        customer.notes = prospect.notes
        customer.appointments = prospect.appointments
        customer.knockHistory = prospect.knockHistory

        // Insert into DB
        modelContext.insert(customer)
        modelContext.delete(prospect)

        do {
            try modelContext.save()
            return customer
        } catch {
            print("❌ Failed to convert prospect: \(error)")
            return nil
        }
    }
    
    func shareProspect(_ prospect: Prospect) {
        var components = URLComponents()
        components.scheme = "d2dcrm"
        components.host = "import"
        components.queryItems = [
            URLQueryItem(name: "fullName", value: prospect.fullName),
            URLQueryItem(name: "address", value: prospect.address),
            URLQueryItem(name: "phone", value: prospect.contactPhone),
            URLQueryItem(name: "email", value: prospect.contactEmail)
        ]
        
        guard let deepLink = components.url else { return }
        let appStoreURL = URL(string: "https://apps.apple.com/us/app/d2d-studio/id6748091911")!
        
        let message = """
        Check out this contact in D2D CRM!
        
        Download here: \(appStoreURL.absoluteString)
        
        After installing, open this link to import: \(deepLink.absoluteString)
        """
        
        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
    
    func fetchAddress(for completion: MKLocalSearchCompletion, prospect: Prospect) {
        Task {
            if let fullAddress = await SearchBarController.resolveFormattedPostalAddress(from: completion) {
                prospect.address = fullAddress
            }
        }
    }
    
    @discardableResult
    func validatePhoneNumber() -> Bool {
        if let error = PhoneValidator.validate(tempPhone) {
            phoneError = error
            return false
        } else {
            phoneError = nil
            return true
        }
    }
    
}
