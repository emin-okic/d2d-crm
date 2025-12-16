//
//  ContactManagerController.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import Foundation
import SwiftData

@MainActor
class ContactManagerController: ObservableObject {
    @Published var suggestedProspect: Prospect?
    private var suggestionSourceIndex = 0
    
    // 🔑 Now uses customers directly
    func fetchNextSuggestedNeighbor(from customers: [Customer], existingProspects: [Prospect]) async {
        guard !customers.isEmpty else {
            suggestedProspect = nil
            return
        }

        var attemptIndex = suggestionSourceIndex
        var found: Prospect?

        for _ in 0..<customers.count {
            guard !customers.isEmpty else { break }

            // Clamp index
            let safeIndex = attemptIndex % customers.count
            let customer = customers[safeIndex]

            let result = await withCheckedContinuation { (continuation: CheckedContinuation<Prospect?, Never>) in
                DatabaseController.shared.geocodeAndSuggestNeighbor(from: customer.address) { address, coordinate in
                    if let addr = address,
                       let coord = coordinate,
                       !existingProspects.contains(where: {
                           $0.address.caseInsensitiveCompare(addr) == .orderedSame
                       }) {

                        let suggested = Prospect(
                            fullName: "Suggested Neighbor",
                            address: addr,
                            count: 0,
                            list: "Prospects"
                        )

                        // 🔑 Attach coordinates here
                        suggested.latitude = coord.latitude
                        suggested.longitude = coord.longitude
                        
                        // 🧪 Debug print on creation
                        print("""
                        📍 Suggested Prospect Created
                        Address: \(addr)
                        Latitude: \(coord.latitude)
                        Longitude: \(coord.longitude)
                        """)

                        continuation.resume(returning: suggested)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }

            if let valid = result {
                found = valid
                suggestionSourceIndex = (safeIndex + 1) % customers.count
                break
            }

            attemptIndex = (safeIndex + 1) % customers.count
        }

        suggestedProspect = found
    }
}
