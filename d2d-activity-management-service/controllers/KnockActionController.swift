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
        let contact = saveKnock(
            address: address,
            status: status,
            prospects: prospects,
            customers: customers
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onUpdateMarkers()
        }

        // Only prospects get notes
        guard status != "Wasn't Home",
              case .prospect(let prospect) = contact
        else { return }

        onShowNoteInput(prospect)
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
        let contact = saveKnock(
            address: address,
            status: status,
            prospects: prospects,
            customers: customers
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onUpdateMarkers()
        }

        // Objections are only for prospects
        guard case .prospect(let prospect) = contact else { return }

        let filtered = objections.filter { $0.text != "Converted To Sale" }

        if filtered.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onShowAddObjection(prospect)
            }
        } else {
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

    private func saveKnock(
        address: String,
        status: String,
        prospects: [Prospect],
        customers: [Customer]
    ) -> ResolvedContact {

        guard var contact = resolveContact(
            address: address,
            prospects: prospects,
            customers: customers
        ) else {
            fatalError("Attempted to log knock for unknown address: \(address)")
        }

        let now = Date()
        let location = locationManager.currentLocation
        let lat = location?.latitude ?? contact.latitude ?? 0
        let lon = location?.longitude ?? contact.longitude ?? 0

        contact.knockCount += 1
        contact.knockHistory.append(
            Knock(date: now, status: status, latitude: lat, longitude: lon)
        )

        controller.performSearch(query: address)
        try? modelContext.save()

        return contact
    }
    
    private func resolveContact(
        address: String,
        prospects: [Prospect],
        customers: [Customer]
    ) -> ResolvedContact? {

        let normalized = address
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let customer = customers.first(where: {
            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }) {
            return .customer(customer)
        }

        if let prospect = prospects.first(where: {
            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }) {
            return .prospect(prospect)
        }

        return nil
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
    ) -> ResolvedContact {

        let contact = saveKnock(
            address: address,
            status: status,
            prospects: prospects,
            customers: customers
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onUpdateMarkers()
        }

        return contact
    }
}

enum ResolvedContact {
    case prospect(Prospect)
    case customer(Customer)

    var address: String {
        switch self {
        case .prospect(let p): return p.address
        case .customer(let c): return c.address
        }
    }

    var knockHistory: [Knock] {
        get {
            switch self {
            case .prospect(let p): return p.knockHistory
            case .customer(let c): return c.knockHistory
            }
        }
        set {
            switch self {
            case .prospect(let p): p.knockHistory = newValue
            case .customer(let c): c.knockHistory = newValue
            }
        }
    }

    var knockCount: Int {
        get {
            switch self {
            case .prospect(let p): return p.knockCount
            case .customer(let c): return c.knockCount
            }
        }
        set {
            switch self {
            case .prospect(let p): p.knockCount = newValue
            case .customer(let c): c.knockCount = newValue
            }
        }
    }

    var latitude: Double? {
        get {
            switch self {
            case .prospect(let p): return p.latitude
            case .customer(let c): return c.latitude
            }
        }
        set {
            switch self {
            case .prospect(let p): p.latitude = newValue
            case .customer(let c): c.latitude = newValue
            }
        }
    }

    var longitude: Double? {
        get {
            switch self {
            case .prospect(let p): return p.longitude
            case .customer(let c): return c.longitude
            }
        }
        set {
            switch self {
            case .prospect(let p): p.longitude = newValue
            case .customer(let c): c.longitude = newValue
            }
        }
    }
}
