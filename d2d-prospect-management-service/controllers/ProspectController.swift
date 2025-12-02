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
import CoreLocation

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
    
    func shareProspect(_ prospect: Prospect) {
        // Construct deep link
        var components = URLComponents()
        components.scheme = "d2dcrm"
        components.host = "import"
        components.queryItems = [
            URLQueryItem(name: "fullName", value: prospect.fullName),
            URLQueryItem(name: "address", value: prospect.address),
            URLQueryItem(name: "phone", value: prospect.contactPhone),
            URLQueryItem(name: "email", value: prospect.contactEmail)
        ]

        guard let deepLink = components.url else {
            print("❌ Failed to generate deep link")
            return
        }

        let appStoreURL = URL(string: "https://apps.apple.com/us/app/d2d-studio/id6748091911")!
        let message = """
        Check out this contact in D2D Studio CRM!

        Download the app:
        \(appStoreURL.absoluteString)

        Then tap this link to import:
        \(deepLink.absoluteString)
        """

        // Use modern iOS presentation-safe share sheet
        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)

        // ✅ Find top-most view controller for presentation
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                  let window = scene.windows.first(where: { $0.isKeyWindow }),
                  let root = window.rootViewController else {
                print("❌ Could not find active window to present share sheet")
                return
            }

            // Traverse presented stack to top-most controller
            var topController = root
            while let presented = topController.presentedViewController {
                topController = presented
            }

            topController.present(activityVC, animated: true)
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

extension ProspectController {

    /// Re-geocode the address after edits and update latitude/longitude.
    @MainActor
    func updateCoordinatesIfAddressChanged(_ prospect: Prospect,
                                           oldAddress: String,
                                           modelContext: ModelContext) async {

        let newAddress = prospect.address.trimmingCharacters(in: .whitespacesAndNewlines)
        let oldAddressClean = oldAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        guard newAddress.caseInsensitiveCompare(oldAddressClean) != .orderedSame else {
            return  // Address not changed — no geocoding needed
        }

        let geocoder = CLGeocoder()
        if let marks = try? await geocoder.geocodeAddressString(newAddress),
           let coord = marks.first?.location?.coordinate {

            prospect.latitude = coord.latitude
            prospect.longitude = coord.longitude

            try? modelContext.save()

            // Notify map to refresh markers
            NotificationCenter.default.post(
                name: .mapShouldRecenterAllMarkers,
                object: nil
            )
        }
    }
}
