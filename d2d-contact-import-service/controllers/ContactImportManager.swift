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
            CLGeocoder().geocodeAddressString(addressString) { placemarks, _ in
                if let coord = placemarks?.first?.location?.coordinate {
                    newProspect.latitude = coord.latitude
                    newProspect.longitude = coord.longitude
                }
                self.modelContext.insert(newProspect)
                try? self.modelContext.save()
                self.onSave()
            }

            didAddAny = true
        }

        return (didAddAny, duplicateNames)
    }
}
