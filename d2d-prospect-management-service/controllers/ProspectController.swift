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
    
}
