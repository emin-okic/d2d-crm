//
//  ContactManagerController.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import Foundation
import SwiftData
import CoreLocation

@MainActor
class ContactManagerController: ObservableObject {
    
    @Published var suggestedProspect: Prospect?
    
    private var suggestionSourceIndex = 0
    
    var geocodeNeighborClosure: ((_ address: String, _ existingProspects: [Prospect], _ completion: @escaping (String?, CLLocationCoordinate2D?) -> Void) -> Void)?
    
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
                
                // Use injected closure if available, otherwise default behavior
                let geocodeFunction = geocodeNeighborClosure ?? self.geocodeAndSuggestNeighbor
                geocodeFunction(customer.address, existingProspects) { addr, coord in
                    guard let addr, let coord else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let suggested = Prospect(
                        fullName: "Suggested Neighbor",
                        address: addr,
                        count: 0,
                        list: "Prospects"
                    )
                    suggested.latitude = coord.latitude
                    suggested.longitude = coord.longitude
                    continuation.resume(returning: suggested)
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
    
    /// Attempts to geocode a customer address and suggests a neighbor not already in existingProspects.
    fileprivate func geocodeAndSuggestNeighbor(
        from customerAddress: String,
        existingProspects: [Prospect],
        completion: @escaping (_ address: String?, _ coordinate: CLLocationCoordinate2D?) -> Void
    ) {
        let components = customerAddress.components(separatedBy: " ")
        guard let first = components.first,
              let baseNumber = Int(first) else {
            completion(nil, nil)
            return
        }

        let streetRemainder = components.dropFirst().joined(separator: " ")
        let maxAttempts = 10
        let existingAddresses = existingProspects.map { $0.address.lowercased() }
        let geocoder = CLGeocoder()

        func tryOffset(_ offset: Int) {
            let newAddress = "\(baseNumber + offset) \(streetRemainder)"

            if existingAddresses.contains(newAddress.lowercased()) {
                offset < maxAttempts ? tryOffset(offset + 1) : completion(nil, nil)
                return
            }

            geocoder.geocodeAddressString(newAddress) { placemarks, _ in
                guard let location = placemarks?.first?.location else {
                    offset < maxAttempts ? tryOffset(offset + 1) : completion(nil, nil)
                    return
                }
                completion(newAddress, location.coordinate)
            }
        }

        tryOffset(1)
    }
    
}
