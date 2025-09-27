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
            let customer = customers[attemptIndex]

            let result = await withCheckedContinuation { (continuation: CheckedContinuation<Prospect?, Never>) in
                DatabaseController.shared.geocodeAndSuggestNeighbor(from: customer.address) { address in
                    if let addr = address,
                       !existingProspects.contains(where: { $0.address.caseInsensitiveCompare(addr) == .orderedSame }) {
                        let suggested = Prospect(
                            fullName: "Suggested Neighbor",
                            address: addr,
                            count: 0,
                            list: "Prospects"
                        )
                        continuation.resume(returning: suggested)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }

            if let valid = result {
                found = valid
                suggestionSourceIndex = (attemptIndex + 1) % customers.count
                break
            }

            attemptIndex = (attemptIndex + 1) % customers.count
        }

        suggestedProspect = found
    }
}
