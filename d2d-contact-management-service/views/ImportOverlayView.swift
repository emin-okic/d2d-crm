//
//  ImportOverlayView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/12/25.
//


import SwiftUI
import SwiftData
import ContactsUI
import CoreLocation

struct ImportOverlayView: View {
    @Binding var showingImportFromContacts: Bool
    @Binding var showImportSuccess: Bool
    @Binding var selectedList: String
    @Binding var searchText: String

    let prospects: [Prospect]
    let modelContext: ModelContext
    let onSave: () -> Void
    
    let onAddManually: () -> Void

    @State private var showContactsPicker = false
    
    @State private var showBusinessCardScanner = false
    @State private var scannedProspectDraft: ProspectDraft?

    var body: some View {
        if showingImportFromContacts {
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                VStack(spacing: 6) {
                    Text("Add Prospect")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Choose how you’d like to add a new prospect")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    
                    actionButton(
                        title: "Import from Contacts",
                        subtitle: "Select one or more contacts",
                        systemImage: "person.crop.circle.badge.plus"
                    ) {
                        showContactsPicker = true
                    }

                    actionButton(
                        title: "Add Manually",
                        subtitle: "Enter details yourself",
                        systemImage: "square.and.pencil"
                    ) {
                        showingImportFromContacts = false
                        
                        onAddManually()
                    }
                    
                    actionButton(
                        title: "Scan Business Card",
                        subtitle: "Use your camera to add a prospect",
                        systemImage: "camera.viewfinder"
                    ) {
                        showBusinessCardScanner = true
                    }
                }
                
                Button("Cancel") {
                    showingImportFromContacts = false
                }
                .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .frame(maxWidth: 340, maxHeight: 400)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 8)
            .position(
                x: UIScreen.main.bounds.midX,
                y: UIScreen.main.bounds.midY
            )
            .transition(.scale.combined(with: .opacity))
            .zIndex(2000)
            .sheet(isPresented: $showContactsPicker) {
                ContactsImportView(
                    onComplete: handleContactsImported,
                    onCancel: { showContactsPicker = false }
                )
            }
            .sheet(item: $scannedProspectDraft) { draft in
                BusinessCardConfirmView(
                    draft: draft,
                    onConfirm: { confirmedDraft in
                        saveProspect(confirmedDraft)
                        scannedProspectDraft = nil
                        showingImportFromContacts = false
                    }
                )
            }
            .sheet(isPresented: $showBusinessCardScanner) {
                BusinessCardScannerView(
                    onScanned: { draft in
                        scannedProspectDraft = draft
                        showBusinessCardScanner = false
                    },
                    onCancel: {
                        showBusinessCardScanner = false
                    }
                )
            }
        }
    }
    
    private func saveProspect(_ draft: ProspectDraft) {
        let prospect = Prospect(
            fullName: draft.fullName,
            address: draft.address,
            list: "Prospects"
        )

        prospect.contactPhone = draft.phone
        prospect.contactEmail = draft.email

        CLGeocoder().geocodeAddressString(draft.address) { placemarks, _ in
            if let coord = placemarks?.first?.location?.coordinate {
                prospect.latitude = coord.latitude
                prospect.longitude = coord.longitude
            }

            modelContext.insert(prospect)
            try? modelContext.save()
            onSave()
        }
    }

    // MARK: - Import Logic

    private func handleContactsImported(_ contacts: [CNContact]) {
        showContactsPicker = false
        showingImportFromContacts = false

        for contact in contacts {
            let fullName =
                CNContactFormatter.string(from: contact, style: .fullName)
                ?? "No Name"

            let addressString =
                contact.postalAddresses.first.map {
                    CNPostalAddressFormatter
                        .string(from: $0.value, style: .mailingAddress)
                        .replacingOccurrences(of: "\n", with: ", ")
                } ?? "No Address"

            let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
            let email = contact.emailAddresses.first?.value as String? ?? ""

            let isDuplicate = prospects.contains {
                $0.fullName == fullName && $0.address == addressString
            }

            guard !isDuplicate else { continue }

            let newProspect = Prospect(
                fullName: fullName,
                address: addressString,
                count: 0,
                list: "Prospects"
            )

            newProspect.contactPhone = phone
            newProspect.contactEmail = email

            CLGeocoder().geocodeAddressString(addressString) { placemarks, _ in
                if let coord = placemarks?.first?.location?.coordinate {
                    newProspect.latitude = coord.latitude
                    newProspect.longitude = coord.longitude
                }

                modelContext.insert(newProspect)
                try? modelContext.save()
                onSave()
            }
        }

        selectedList = "Prospects"
        searchText = ""
        showImportSuccess = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showImportSuccess = false
        }
    }

    // MARK: - Button

    private func actionButton(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
        }
        .buttonStyle(.plain)
    }
}
