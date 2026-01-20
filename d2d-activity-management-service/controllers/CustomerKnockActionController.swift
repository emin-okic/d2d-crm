//
//  CustomerKnockActionController.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/18/25.
//

import Foundation
import SwiftData
import MapKit

@MainActor
class CustomerKnockActionController {
    private let modelContext: ModelContext
    private let controller: MapController
    private let locationManager = LocationManager.shared

    init(modelContext: ModelContext, controller: MapController) {
        self.modelContext = modelContext
        self.controller = controller
    }

    func handleKnockAndUpdateMarker(
        address: String,
        status: String,
        customers: [Customer],
        onUpdateMarkers: () -> Void
    ) {
        if let customer = customers.first(where: {
            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
            address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }) {
            _ = saveKnock(address: address, status: status, customers: customers)
            onUpdateMarkers()
        }
    }

    /// Core Logic For Saving Knocks

    private func saveKnock(address: String, status: String, customers: [Customer]) -> Customer {
        let normalized = address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let location = locationManager.currentLocation
        let lat = location?.latitude ?? 0.0
        let lon = location?.longitude ?? 0.0

        var updatedCustomer: Customer

        if let existing = customers.first(where: { $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized }) {
            existing.knockCount += 1
            existing.knockHistory.append(Knock(date: now, status: status, latitude: lat, longitude: lon))
            updatedCustomer = existing
        } else {
            let newCustomer = Customer(fullName: "New Customer", address: address, count: 1)
            newCustomer.knockHistory = [Knock(date: now, status: status, latitude: lat, longitude: lon)]
            modelContext.insert(newCustomer)
            updatedCustomer = newCustomer

            _ = DatabaseController.shared.addCustomer(name: newCustomer.fullName, addr: newCustomer.address)
            _ = DatabaseController.shared.addKnock(forCustomer: updatedCustomer)
        }

        controller.performSearch(query: address)
        try? modelContext.save()

        return updatedCustomer
    }

    @discardableResult
    func saveKnockOnly(address: String, status: String, customers: [Customer], onUpdateMarkers: @escaping () -> Void) -> Customer {
        let c = saveKnock(address: address, status: status, customers: customers)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onUpdateMarkers() }
        return c
    }
}
