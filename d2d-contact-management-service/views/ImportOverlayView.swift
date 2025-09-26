//
//  ImportOverlayView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/12/25.
//


import SwiftUI
import SwiftData
import ContactsUI

struct ImportOverlayView: View {
    @Binding var showingImportFromContacts: Bool
    @Binding var showImportSuccess: Bool
    @Binding var selectedList: String
    @Binding var searchText: String
    var prospects: [Prospect]
    var modelContext: ModelContext
    var onSave: () -> Void

    var body: some View {
        if showingImportFromContacts {
            ContactsImportView(
                onComplete: { contacts in
                    showingImportFromContacts = false

                    for contact in contacts {
                        let fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? "No Name"
                        let addressString = contact.postalAddresses.first.map {
                            CNPostalAddressFormatter.string(from: $0.value, style: .mailingAddress).replacingOccurrences(of: "\n", with: ", ")
                        } ?? "No Address"
                        let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
                        let email = contact.emailAddresses.first?.value as String? ?? ""

                        let newProspect = Prospect(fullName: fullName, address: addressString, count: 0, list: "Prospects")
                        newProspect.contactEmail = email
                        newProspect.contactPhone = phoneNumber

                        let isDuplicate = prospects.contains {
                            $0.fullName == fullName && $0.address == addressString
                        }

                        if !isDuplicate {
                            modelContext.insert(newProspect)
                        }
                    }

                    try? modelContext.save()
                    selectedList = "Prospects"
                    searchText = ""
                    onSave()

                    showImportSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showImportSuccess = false
                    }
                },
                onCancel: {
                    showingImportFromContacts = false
                }
            )
            .frame(width: 300, height: 400)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 8)
            .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
            .transition(.scale.combined(with: .opacity))
            .zIndex(2000)
        }
    }
}
