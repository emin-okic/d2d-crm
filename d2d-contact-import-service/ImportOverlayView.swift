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
import MapKit

struct ImportOverlayView: View {
    @Binding var showingImportFromContacts: Bool
    @Binding var showImportSuccess: Bool
    @Binding var selectedList: String
    @Binding var searchText: String

    let prospects: [Prospect]
    let customers: [Customer]
    let modelContext: ModelContext
    let onSave: () -> Void
    let onOpenDuplicateProspect: (Prospect) -> Void
    let onOpenDuplicateCustomer: (Customer) -> Void
    
    let onAddManually: () -> Void

    @State private var showContactsPicker = false
    
    @State private var showBusinessCardScanner = false
    @State private var businessCardReview: BusinessCardReview?
    
    @StateObject private var importManager: ContactImportManager
    
    @Binding var showDuplicateToast: Bool
    @Binding var duplicateNames: [String]
    
    // ✅ Custom initializer to properly inject StateObject
    init(
        showingImportFromContacts: Binding<Bool>,
        showImportSuccess: Binding<Bool>,
        selectedList: Binding<String>,
        searchText: Binding<String>,
        prospects: [Prospect],
        customers: [Customer],
        modelContext: ModelContext,
        onSave: @escaping () -> Void,
        onOpenDuplicateProspect: @escaping (Prospect) -> Void,
        onOpenDuplicateCustomer: @escaping (Customer) -> Void,
        onAddManually: @escaping () -> Void,
        showDuplicateToast: Binding<Bool>,
        duplicateNames: Binding<[String]>
    ) {
        self._showingImportFromContacts = showingImportFromContacts
        self._showImportSuccess = showImportSuccess
        self._selectedList = selectedList
        self._searchText = searchText
        self.prospects = prospects
        self.customers = customers
        self.modelContext = modelContext
        self.onSave = onSave
        self.onOpenDuplicateProspect = onOpenDuplicateProspect
        self.onOpenDuplicateCustomer = onOpenDuplicateCustomer
        self.onAddManually = onAddManually

        // ✅ Initialize StateObject here
        _importManager = StateObject(wrappedValue: ContactImportManager(
            modelContext: modelContext,
            prospects: prospects,
            customers: customers,
            onSave: onSave
        ))
        
        self._showDuplicateToast = showDuplicateToast
        self._duplicateNames = duplicateNames
    }

    var body: some View {
        
        if showingImportFromContacts {
            GeometryReader { geometry in
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
                        
                        // Haptics + sound on option tap
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        
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
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(2000)
                .sheet(isPresented: $showContactsPicker) {
                    ContactsImportView(
                        onComplete: handleContactsImported,
                        onCancel: { showContactsPicker = false }
                    )
                }
                .sheet(item: $businessCardReview) { review in
                    BusinessCardConfirmView(
                        draft: review.draft,
                        duplicate: review.duplicate,
                        onConfirm: { confirmedDraft in
                            saveProspect(confirmedDraft)
                            businessCardReview = nil
                            showingImportFromContacts = false
                        },
                        onUpdateExisting: { duplicate, fields in
                            updateExistingContact(duplicate, with: review.draft, fields: fields)
                            businessCardReview = nil
                            showingImportFromContacts = false
                        },
                        onOpenExisting: { duplicate in
                            openExistingContact(duplicate)
                            businessCardReview = nil
                            showingImportFromContacts = false
                        }
                    )
                }
                .sheet(isPresented: $showBusinessCardScanner) {
                    BusinessCardScannerView(
                        onScanned: { draft in
                            showBusinessCardScanner = false
                            let review = BusinessCardReview(
                                draft: draft,
                                duplicate: findDuplicate(for: draft)
                            )
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                businessCardReview = review
                            }
                        },
                        onCancel: {
                            showBusinessCardScanner = false
                        }
                    )
                }
            }
        }
    }
    
    private func findDuplicate(for draft: ProspectDraft) -> BusinessCardDuplicateCandidate? {
        let currentProspects = (try? modelContext.fetch(FetchDescriptor<Prospect>())) ?? prospects
        let currentCustomers = (try? modelContext.fetch(FetchDescriptor<Customer>())) ?? customers

        if let prospect = currentProspects.first(where: { isDuplicate(draft, of: $0) }) {
            return BusinessCardDuplicateCandidate(prospect: prospect)
        }

        if let customer = currentCustomers.first(where: { isDuplicate(draft, of: $0) }) {
            return BusinessCardDuplicateCandidate(customer: customer)
        }

        return nil
    }

    private func isDuplicate(_ draft: ProspectDraft, of contact: any ContactProtocol) -> Bool {
        let draftName = normalizedText(draft.fullName)
        let contactName = normalizedText(contact.fullName)
        if isUsableName(draftName), isUsableName(contactName), draftName == contactName {
            return true
        }

        let draftAddress = normalizedText(draft.address)
        let contactAddress = normalizedText(contact.address)
        if isUsableAddress(draftAddress), isUsableAddress(contactAddress), draftAddress == contactAddress {
            return true
        }

        let draftEmail = normalizedEmail(draft.email)
        let contactEmail = normalizedEmail(contact.contactEmail)
        if !draftEmail.isEmpty, !contactEmail.isEmpty, draftEmail == contactEmail {
            return true
        }

        let draftPhone = digitsOnly(draft.phone)
        let contactPhone = digitsOnly(contact.contactPhone)
        if phoneNumbersMatch(draftPhone, contactPhone) {
            return true
        }

        return false
    }

    private func updateExistingContact(
        _ duplicate: BusinessCardDuplicateCandidate,
        with draft: ProspectDraft,
        fields: Set<BusinessCardMergeField>
    ) {
        switch duplicate.type {
        case .prospect:
            guard let prospect = duplicate.prospect else { return }
            apply(draft, to: prospect, fields: fields)
        case .customer:
            guard let customer = duplicate.customer else { return }
            apply(draft, to: customer, fields: fields)
        }

        try? modelContext.save()
        onSave()
    }

    private func apply(_ draft: ProspectDraft, to contact: any ContactProtocol, fields: Set<BusinessCardMergeField>) {
        var contact = contact

        if fields.contains(.name), !draft.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            contact.fullName = draft.fullName
        }
        if fields.contains(.email), !draft.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            contact.contactEmail = draft.email
        }
        if fields.contains(.phone), !draft.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            contact.contactPhone = draft.phone
        }
        if fields.contains(.address), isUsableAddress(normalizedText(draft.address)) {
            contact.address = draft.address
        }
    }

    private func openExistingContact(_ duplicate: BusinessCardDuplicateCandidate) {
        switch duplicate.type {
        case .prospect:
            guard let prospect = duplicate.prospect else { return }
            selectedList = "Prospects"
            DispatchQueue.main.async {
                onOpenDuplicateProspect(prospect)
            }
        case .customer:
            guard let customer = duplicate.customer else { return }
            selectedList = "Customers"
            DispatchQueue.main.async {
                onOpenDuplicateCustomer(customer)
            }
        }
    }

    private func normalizedEmail(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normalizedText(_ value: String) -> String {
        let folded = value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        let scalars = folded.unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        }

        return String(scalars)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    private func isUsableName(_ value: String) -> Bool {
        !value.isEmpty && value != "unknown" && value.split(separator: " ").count >= 2
    }

    private func isUsableAddress(_ value: String) -> Bool {
        !value.isEmpty && value != "no address" && value != "noaddress"
    }

    private func digitsOnly(_ value: String) -> String {
        value.filter(\.isNumber)
    }

    private func phoneNumbersMatch(_ lhs: String, _ rhs: String) -> Bool {
        guard lhs.count >= 7, rhs.count >= 7 else { return false }
        if lhs == rhs { return true }

        return lhs.suffix(7) == rhs.suffix(7)
    }

    private func saveProspect(_ draft: ProspectDraft) {
        let prospect = Prospect(
            fullName: draft.fullName,
            address: draft.address,
            list: "Prospects"
        )

        prospect.contactPhone = draft.phone
        prospect.contactEmail = draft.email

        Task { @MainActor in
            if let coordinate = await coordinate(for: draft.address) {
                prospect.latitude = coordinate.latitude
                prospect.longitude = coordinate.longitude
            }

            modelContext.insert(prospect)
            try? modelContext.save()
            onSave()
        }
    }

    private func coordinate(for addressString: String) async -> (latitude: Double, longitude: Double)? {
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

    // MARK: - Import Logic

    private func handleContactsImported(_ contacts: [CNContact]) {
        showContactsPicker = false
        showingImportFromContacts = false

        let (didAdd, duplicates) = importManager.importContacts(contacts)

        selectedList = "Prospects"
        searchText = ""

        if didAdd {
            showImportSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showImportSuccess = false
            }
        }

        if !duplicates.isEmpty {
            duplicateNames = duplicates
            showDuplicateToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showDuplicateToast = false
            }
        }
    }

    // MARK: - Button

    private func actionButton(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            // Haptics + sound on option tap
            ContactScreenHapticsController.shared.lightTap()
            ContactScreenSoundController.shared.playSound1()
            
            action()
        } label: {
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
