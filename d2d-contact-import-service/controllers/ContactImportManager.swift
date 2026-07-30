//
//  ContactImportManager.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI
import SwiftData
import Contacts
import CoreLocation
import MapKit

@MainActor
final class ContactImportManager: ObservableObject {
    let modelContext: ModelContext
    let prospects: [Prospect]
    let customers: [Customer]
    let onSave: () -> Void

    init(modelContext: ModelContext,
         prospects: [Prospect],
         customers: [Customer],
         onSave: @escaping () -> Void) {
        self.modelContext = modelContext
        self.prospects = prospects
        self.customers = customers
        self.onSave = onSave
    }

    /// Returns: (didAddAny, duplicateNames)
    func importContacts(_ contacts: [CNContact]) -> (Bool, [String]) {
        var didAddAny = false
        var duplicateNames: [String] = []

        for contact in contacts {
            let fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? "No Name"
            let addressString = contact.postalAddresses.first.map {
                CNPostalAddressFormatter
                    .string(from: $0.value, style: .mailingAddress)
                    .replacingOccurrences(of: "\n", with: ", ")
            } ?? "No Address"

            let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
            let email = contact.emailAddresses.first?.value as String? ?? ""

            // ✅ Dynamically check duplicates in modelContext
            let existingProspect = try? modelContext.fetch(FetchDescriptor<Prospect>(predicate: #Predicate { $0.fullName == fullName && $0.address == addressString }))
            let existingCustomer = try? modelContext.fetch(FetchDescriptor<Customer>(predicate: #Predicate { $0.fullName == fullName && $0.address == addressString }))

            if let p = existingProspect, !p.isEmpty {
                duplicateNames.append(fullName)
                continue
            }
            if let c = existingCustomer, !c.isEmpty {
                duplicateNames.append(fullName)
                continue
            }

            // Insert only unique prospects
            let newProspect = Prospect(
                fullName: fullName,
                address: addressString,
                count: 0,
                list: "Prospects"
            )
            newProspect.contactPhone = phone
            newProspect.contactEmail = email

            // Geocode asynchronously
            Task { @MainActor in
                if let coordinate = await Self.coordinate(for: addressString) {
                    newProspect.latitude = coordinate.latitude
                    newProspect.longitude = coordinate.longitude
                }

                modelContext.insert(newProspect)
                try? modelContext.save()
                onSave()
            }

            didAddAny = true
        }

        return (didAddAny, duplicateNames)
    }

    private static func coordinate(for addressString: String) async -> (latitude: Double, longitude: Double)? {
        guard addressString != "No Address" else { return nil }

        if #available(iOS 26.0, *) {
            guard let request = MKGeocodingRequest(addressString: addressString) else { return nil }

            do {
                let mapItems = try await request.mapItems
                guard let mapItem = mapItems.first else { return nil }
                let coordinate = mapItem.location.coordinate
                return (coordinate.latitude, coordinate.longitude)
            } catch {
                return nil
            }
        } else {
            do {
                let placemarks = try await CLGeocoder().geocodeAddressString(addressString)
                guard let coordinate = placemarks.first?.location?.coordinate else { return nil }
                return (coordinate.latitude, coordinate.longitude)
            } catch {
                return nil
            }
        }
    }
}
