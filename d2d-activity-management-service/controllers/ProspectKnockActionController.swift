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
class ProspectKnockActionController {
    private let modelContext: ModelContext
    private let controller: MapController
    private let locationManager = LocationManager.shared

    init(modelContext: ModelContext, controller: MapController) {
        self.modelContext = modelContext
        self.controller = controller
    }

    @discardableResult
    func handleKnockAndPromptNote(
        address: String,
        status: String,
        prospects: [Prospect],
        onUpdateMarkers: @escaping () -> Void
    ) -> Prospect? {
        let prospect = saveKnock(address: address, status: status, prospects: prospects)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onUpdateMarkers()
        }

        return status != "Wasn't Home" ? prospect : nil
    }

    private func saveKnock(address: String, status: String, prospects: [Prospect]) -> Prospect {
        let normalized = address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let location = locationManager.currentLocation
        let lat = location?.latitude ?? 0.0
        let lon = location?.longitude ?? 0.0

        var prospectId: Int64?
        var updated: Prospect

        if let existing = prospects.first(where: {
            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }) {
            existing.knockCount += 1
            
            existing.knockHistory.append(Knock(date: now, status: status, latitude: lat, longitude: lon))
            
            // ⭐️ STEP 3: mark unqualified + update name once
            if status == "Unqualified" {
                existing.isUnqualified = true

                if !existing.fullName.contains("Unqualified") {
                    existing.fullName = "\(existing.fullName) - Unqualified"
                }
            }
            
            updated = existing
            
        } else {
            let new = Prospect(fullName: "New Prospect", address: address, count: 1, list: "Prospects")
            new.knockHistory = [Knock(date: now, status: status, latitude: lat, longitude: lon)]
            modelContext.insert(new)
            updated = new

            if let newId = DatabaseController.shared.addProspect(name: new.fullName, addr: new.address) {
                prospectId = newId
            }
        }

        if let id = prospectId {
            DatabaseController.shared.addKnock(for: id, date: now, status: status, latitude: lat, longitude: lon)
        }

        controller.performSearch(query: address)
        try? modelContext.save()

        return updated
    }
}

extension ProspectKnockActionController {
    @discardableResult
    func saveKnockOnly(address: String, status: String, prospects: [Prospect], onUpdateMarkers: @escaping () -> Void) -> Prospect {
        let p = saveKnock(address: address, status: status, prospects: prospects)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onUpdateMarkers() }
        return p
    }
}
