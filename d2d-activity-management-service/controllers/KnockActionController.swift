//
//  KnockActionController.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/7/25.
//


import Foundation
import SwiftData
import MapKit

@MainActor
class KnockActionController {
    private let modelContext: ModelContext
    private let controller: MapController
    private let locationManager = LocationManager.shared

    init(modelContext: ModelContext, controller: MapController) {
        self.modelContext = modelContext
        self.controller = controller
    }

    func handleKnockAndPromptNote(
        address: String,
        status: String,
        prospects: [Prospect],
        customers: [Customer],
        onUpdateMarkers: @escaping () -> Void,
        onShowNoteInput: @escaping (Prospect) -> Void
    ) {
        let resolved = saveKnock(
            address: address,
            status: status,
            prospects: prospects,
            customers: customers
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onUpdateMarkers()
        }

        if status != "Wasn't Home",
           case .prospect(let prospect)? = resolved {
            onShowNoteInput(prospect)
        }
    }

    func handleKnockAndPromptObjection(
        address: String,
        status: String,
        prospects: [Prospect],
        customers: [Customer],
        objections: [Objection],
        onUpdateMarkers: @escaping () -> Void,
        onShowObjectionPicker: @escaping ([Objection], Prospect) -> Void,
        onShowAddObjection: @escaping (Prospect) -> Void
    ) {
        let resolved = saveKnock(
            address: address,
            status: status,
            prospects: prospects,
            customers: customers
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onUpdateMarkers()
        }

        guard case .prospect(let prospect)? = resolved else { return }

        if objections.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onShowAddObjection(prospect)
            }
        } else {
            let filtered = objections.filter { $0.text != "Converted To Sale" }
            onShowObjectionPicker(filtered, prospect)
        }
    }

    func handleKnockAndConvertToCustomer(
        address: String,
        status: String,
        prospects: [Prospect],
        onUpdateMarkers: () -> Void,
        onSetCustomerMarker: () -> Void,
        onShowConversionSheet: @escaping (Prospect) -> Void
    ) {
        if let prospect = prospects.first(where: {
            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
            address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }) {
            
            onShowConversionSheet(prospect)

            // Update map marker
            onSetCustomerMarker()
            onUpdateMarkers()
        }
    }
    
    enum ResolvedContact {
        case prospect(Prospect)
        case customer(Customer)
    }
    
    private func resolveContact(
        address: String,
        prospects: [Prospect],
        customers: [Customer]
    ) -> ResolvedContact? {

        let key = knockAddressKey(address)

        if let prospect = prospects.first(where: {
            knockAddressKey($0.address) == key
        }) {
            return .prospect(prospect)
        }

        if let customer = customers.first(where: {
            knockAddressKey($0.address) == key
        }) {
            return .customer(customer)
        }

        return nil
    }

    private func saveProspectKnock(
        _ prospect: Prospect,
        address: String,
        status: String
    ) {
        let now = Date()

        let location = locationManager.currentLocation
        let lat = location?.latitude ?? prospect.latitude ?? 0
        let lon = location?.longitude ?? prospect.longitude ?? 0

        prospect.knockCount += 1
        prospect.knockHistory.append(
            Knock(date: now, status: status, latitude: lat, longitude: lon)
        )

        if let sqliteId = DatabaseController.shared.sqliteProspectId(forAddress: prospect.address) {
            DatabaseController.shared.addKnock(
                for: sqliteId,
                date: now,
                status: status,
                latitude: lat,
                longitude: lon
            )
        }

        try? modelContext.save()
    }
    
    private func saveCustomerKnock(
        _ customer: Customer,
        address: String,
        status: String
    ) {
        let now = Date()

        let location = locationManager.currentLocation
        let lat = location?.latitude ?? customer.latitude ?? 0
        let lon = location?.longitude ?? customer.longitude ?? 0

        customer.knockCount += 1
        customer.knockHistory.append(
            Knock(date: now, status: status, latitude: lat, longitude: lon)
        )

        try? modelContext.save()
    }
    
    private func saveKnock(
        address: String,
        status: String,
        prospects: [Prospect],
        customers: [Customer]
    ) -> ResolvedContact? {

        guard let contact = resolveContact(
            address: address,
            prospects: prospects,
            customers: customers
        ) else {
            print("⚠️ Knock ignored — no prospect or customer for address:", address)
            return nil
        }

        switch contact {
        case .prospect(let prospect):
            saveProspectKnock(prospect, address: address, status: status)
            return .prospect(prospect)

        case .customer(let customer):
            saveCustomerKnock(customer, address: address, status: status)
            return .customer(customer)
        }
    }
    
    private func knockAddressKey(_ address: String) -> String {
        address
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension KnockActionController {
    @discardableResult
    func saveKnockOnly(
        address: String,
        status: String,
        prospects: [Prospect],
        customers: [Customer],
        onUpdateMarkers: @escaping () -> Void
    ) -> ResolvedContact? {
        let resolved = saveKnock(
            address: address,
            status: status,
            prospects: prospects,
            customers: customers
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onUpdateMarkers()
        }

        return resolved
    }
}
