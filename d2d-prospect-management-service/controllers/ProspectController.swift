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
    @Published var selectedTab: ProspectDetailsTab = .appointments
    @Published var showNotesSheet: Bool = false
    
    private var baseline: ProspectSnapshot?
    
    func deleteProspect(_ prospect: Prospect, modelContext: ModelContext) {
        // Delete related appointments first
        for appointment in prospect.appointments {
            modelContext.delete(appointment)
        }

        // Delete the prospect
        modelContext.delete(prospect)
        try? modelContext.save()

        // Dismiss any presented UI safely
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.dismiss(animated: true)
            }
        }
    }
    
    func captureBaseline(from prospect: Prospect) {
        baseline = ProspectSnapshot(from: prospect)
        tempPhone = prospect.contactPhone
        tempEmail = prospect.contactEmail
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
    
}
