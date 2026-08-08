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
    
    let onAddManually: () -> Void

    @State private var showContactsPicker = false
    
    @State private var showBusinessCardScanner = false
    @State private var scannedProspectDraft: ProspectDraft?
    
    @StateObject private var importManager: ContactImportManager
    
    @Binding var showDuplicateToast: Bool
    @Binding var duplicateNames: [String]
    @Binding var selectedProspect: Prospect?
    @Binding var selectedCustomer: Customer?

    @State private var duplicateProspectDraft: ProspectDraft?
    
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
        onAddManually: @escaping () -> Void,
        showDuplicateToast: Binding<Bool>,
        duplicateNames: Binding<[String]>,
        selectedProspect: Binding<Prospect?>,
        selectedCustomer: Binding<Customer?>
    ) {
        self._showingImportFromContacts = showingImportFromContacts
        self._showImportSuccess = showImportSuccess
        self._selectedList = selectedList
        self._searchText = searchText
        self.prospects = prospects
        self.customers = customers
        self.modelContext = modelContext
        self.onSave = onSave
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
        self._selectedProspect = selectedProspect
        self._selectedCustomer = selectedCustomer
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
                .sheet(item: $scannedProspectDraft) { draft in
                    BusinessCardConfirmView(
                        draft: draft,
                        onConfirm: { confirmedDraft in
                            handleBusinessCardConfirmed(confirmedDraft)
                        }
                    )
                }
                .sheet(item: $duplicateProspectDraft) { draft in
                    BusinessCardDuplicateResolutionView(
                        draft: draft,
                        candidates: duplicateCandidates(for: draft),
                        onAddNew: {
                            saveProspect(draft)
                            finishBusinessCardImport()
                        },
                        onUpdateExisting: { candidate, fields in
                            updateExistingContact(candidate, with: draft, fields: fields)
                            finishBusinessCardImport()
                        },
                        onViewExisting: { candidate in
                            openExistingContact(candidate)
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
    }
    
    private func handleBusinessCardConfirmed(_ draft: ProspectDraft) {
        let candidates = duplicateCandidates(for: draft)

        if candidates.isEmpty {
            saveProspect(draft)
            finishBusinessCardImport()
        } else {
            scannedProspectDraft = nil
            DispatchQueue.main.async {
                duplicateProspectDraft = draft
            }
        }
    }

    private func finishBusinessCardImport() {
        scannedProspectDraft = nil
        duplicateProspectDraft = nil
        showingImportFromContacts = false
        selectedList = "Prospects"
        searchText = ""
    }

    private func duplicateCandidates(for draft: ProspectDraft) -> [BusinessCardDuplicateCandidate] {
        let prospectMatches = prospects
            .filter { isDuplicate(draft, of: $0) }
            .map { BusinessCardDuplicateCandidate.prospect($0) }

        let customerMatches = customers
            .filter { isDuplicate(draft, of: $0) }
            .map { BusinessCardDuplicateCandidate.customer($0) }

        return prospectMatches + customerMatches
    }

    private func isDuplicate(_ draft: ProspectDraft, of contact: some ContactProtocol) -> Bool {
        let draftEmail = normalizedEmail(draft.email)
        let contactEmail = normalizedEmail(contact.contactEmail)
        if !draftEmail.isEmpty && draftEmail == contactEmail {
            return true
        }

        let draftPhone = normalizedPhone(draft.phone)
        let contactPhone = normalizedPhone(contact.contactPhone)
        if !draftPhone.isEmpty && draftPhone == contactPhone {
            return true
        }

        let draftName = normalizedText(draft.fullName)
        let contactName = normalizedText(contact.fullName)
        let draftAddress = normalizedText(draft.address)
        let contactAddress = normalizedText(contact.address)

        return !draftName.isEmpty &&
            !draftAddress.isEmpty &&
            draftName == contactName &&
            draftAddress == contactAddress
    }

    private func updateExistingContact(
        _ candidate: BusinessCardDuplicateCandidate,
        with draft: ProspectDraft,
        fields: Set<BusinessCardMergeField>
    ) {
        switch candidate {
        case .prospect(let prospect):
            apply(draft, fields: fields, to: prospect)
        case .customer(let customer):
            apply(draft, fields: fields, to: customer)
        }

        try? modelContext.save()
        onSave()
    }

    private func apply(_ draft: ProspectDraft, fields: Set<BusinessCardMergeField>, to prospect: Prospect) {
        if fields.contains(.fullName) {
            prospect.fullName = draft.fullName
        }

        if fields.contains(.email) {
            prospect.contactEmail = draft.email
        }

        if fields.contains(.phone) {
            prospect.contactPhone = draft.phone
        }

        if fields.contains(.address) {
            prospect.address = draft.address
        }
    }

    private func apply(_ draft: ProspectDraft, fields: Set<BusinessCardMergeField>, to customer: Customer) {
        if fields.contains(.fullName) {
            customer.fullName = draft.fullName
        }

        if fields.contains(.email) {
            customer.contactEmail = draft.email
        }

        if fields.contains(.phone) {
            customer.contactPhone = draft.phone
        }

        if fields.contains(.address) {
            customer.address = draft.address
        }
    }

    private func openExistingContact(_ candidate: BusinessCardDuplicateCandidate) {
        scannedProspectDraft = nil
        duplicateProspectDraft = nil
        showingImportFromContacts = false

        switch candidate {
        case .prospect(let prospect):
            selectedList = "Prospects"
            DispatchQueue.main.async {
                selectedProspect = prospect
            }
        case .customer(let customer):
            selectedList = "Customers"
            DispatchQueue.main.async {
                selectedCustomer = customer
            }
        }
    }

    private func normalizedEmail(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normalizedPhone(_ value: String) -> String {
        let digits = value.filter(\.isNumber)
        return digits.count >= 7 ? digits : ""
    }

    private func normalizedText(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return (trimmed.isEmpty || trimmed == "unknown" || trimmed == "no address") ? "" : trimmed
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
