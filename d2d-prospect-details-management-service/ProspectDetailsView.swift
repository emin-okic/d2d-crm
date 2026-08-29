//
//  EditProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData
import CoreLocation
@preconcurrency import Contacts
import MapKit

struct ProspectDetailsView: View {
    @Bindable var prospect: Prospect
    var onNavigateToMap: (MapContactSelection) -> Void = { _ in }
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext

    @StateObject private var controller = ProspectDetailsController()
    
    @StateObject private var searchViewModel = SearchCompleterViewModel()
    @FocusState private var isAddressFieldFocused: Bool

    // 🔑 Local editable copies for deferred saving
    @State private var tempFullName: String = ""
    @State private var tempAddress: String = ""
    
    @State private var showDeleteConfirmation = false
    
    @State private var showRevertConfirmation = false
    
    @State private var actionsToolbarProxy: ProspectActionsToolbar?
    
    @State private var showContactExportOptions = false
    @State private var showExportPrompt = false
    @State private var contactSharePayload: ContactSharePayload?
    @State private var showExportSuccessBanner = false
    @State private var exportSuccessMessage = ""
    
    @State private var showAppointmentsSheet = false
    @State private var showKnocksSheet = false
    @State private var showDemographicsSheet = false
    @State private var demographicsSheetDetent: PresentationDetent = .fraction(0.68)

    var body: some View {
        ZStack {
            
            if showExportSuccessBanner {
                VStack {
                    Spacer().frame(height: 60)
                    Text(exportSuccessMessage)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.95))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .zIndex(1000)
            }
            
            Form {
                Section {
                    Text("Prospect Details")
                        .font(.largeTitle)
                        .bold()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                
                Section {
                    DetailsScorecardCustomizationView(
                        storagePrefix: "prospectDetails",
                        items: prospectScorecardItems
                    )
                }
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                .listRowBackground(Color.clear)
                
                // Prospect info
                Section() {
                    TextField("Full Name", text: $tempFullName)
                    
                    HStack(spacing: 10) {
                        ContactAddressPredictiveTextField(
                            address: $tempAddress,
                            isFocused: $isAddressFieldFocused,
                            searchVM: searchViewModel
                        )

                        if !isAddressPredictionVisible {
                            ContactMapNavigationButton {
                                navigateToMap()
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.18), value: isAddressPredictionVisible)
                }
                
                Section {
                    DemographicsSummaryRow(summary: prospect.demographicsSummary) {
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        showDemographicsSheet = true
                    }
                }
                
                // ✅ Actions Toolbar (unchanged)
                Section {
                    ProspectActionsToolbar(
                        prospect: prospect,
                        modelContext: modelContext
                    )
                }
                
            }
        }
        .sheet(isPresented: $showDeleteConfirmation) {
            DeleteProspectSheet(
                prospectName: prospect.fullName,
                onDelete: {
                    controller.deleteProspect(prospect, modelContext: modelContext)
                }
            )
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
            .onAppear {
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
            }
        }
        .sheet(isPresented: $controller.showNotesSheet) {
            ProspectNotesScreen(prospect: prospect)
        }
        .sheet(isPresented: $showDemographicsSheet) {
            DemographicsEditorView(
                title: "Prospect Demographics",
                initialData: prospect.demographicsFormData,
                onSave: { data in
                    let oldData = prospect.demographicsFormData
                    prospect.applyDemographics(data)
                    if let noteContent = prospect.companyInfoChangeNote(from: oldData, to: data) {
                        prospect.notes.append(Note(content: noteContent, date: Date(), prospect: prospect))
                    }
                    controller.saveProspect(prospect, modelContext: modelContext)
                    showDemographicsSheet = false
                },
                onCancel: {
                    showDemographicsSheet = false
                },
                onExpandedContentChange: { isExpanded in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        demographicsSheetDetent = isExpanded ? .large : .fraction(0.68)
                    }
                }
            )
            .presentationDetents([.fraction(0.68), .large], selection: $demographicsSheetDetent)
            .presentationDragIndicator(.visible)
        }
        // .navigationTitle("Edit Contact")
        .toolbar {
            // Back Button
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    
                    // ✅ Play haptic + sound when closing the details screen
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    // Then dismiss the screen
                    presentationMode.wrappedValue.dismiss()
                    
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
            }
            
            // Export + Share (hidden while editing)
            if !hasUnsavedEdits {
                ToolbarItemGroup(placement: .navigationBarTrailing) {

                    Button {
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        controller.showNotesSheet = true
                    } label: {
                        Image(systemName: "note.text")
                    }

                    Button(role: .destructive) {
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }

                    // ✅ Export to Contacts
                    Button {
                        
                        // ⚡ Haptics & Sound
                        KnockingFormHapticsController.shared.lightTap()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        
                        showContactExportOptions = true
                        
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }

                }
            }

            // Save Button (only appears if name/address changed)
            if hasUnsavedEdits {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    
                    // Revert button
                    Button {
                        // ⚡ Haptics & Sound
                        KnockingFormHapticsController.shared.lightTap()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        
                        showRevertConfirmation = true
                    } label: {
                        Image(systemName: "arrow.uturn.backward") // ⬅ curved backward arrow
                            .foregroundColor(.red)
                            .imageScale(.large)
                    }

                    Button("Save") {
                        
                        // ⚡ Haptics & Sound
                        KnockingFormHapticsController.shared.successFeedbackConfirmation()
                        KnockingFormSoundController.shared.playConfirmationSound()
                        
                        Task {
                            await acceptBestAddressPredictionIfAvailable()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                commitEdits()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
        }
        .sheet(isPresented: $showContactExportOptions) {
            ContactExportOptionsSheet(
                contactName: prospect.fullName,
                onSaveToContacts: {
                    showContactExportOptions = false
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    showExportPromptAfterOptionsDismiss()
                },
                onShareContact: {
                    showContactExportOptions = false
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    shareProspectAfterOptionsDismiss()
                },
                onCancel: {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    showContactExportOptions = false
                }
            )
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showExportPrompt) {
            ContactExportConfirmationSheet(
                contactName: prospect.fullName,
                onConfirm: {
                    showExportPrompt = false
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    exportToContacts()
                },
                onCancel: {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    showExportPrompt = false
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $contactSharePayload) { payload in
            ShareSheet(activityItems: [payload.message])
        }
        .alert("Revert Changes?", isPresented: $showRevertConfirmation) {
            Button("Revert Changes", role: .destructive) {
                
                // ⚡ Subtle feedback on cancel
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                
                revertEdits()
            }
            Button("Cancel", role: .cancel) {
                
                // ⚡ Subtle feedback on cancel
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                
            }
        } message: {
            Text("This will discard all unsaved changes and restore the original prospect details.")
        }
        .onAppear {
            controller.captureBaseline(from: prospect)
            // Initialize local edit copies
            tempFullName = prospect.fullName
            tempAddress = prospect.address
        }
        .sheet(isPresented: $showAppointmentsSheet) {
            NavigationStack {
                ProspectAppointmentsView(
                    prospect: prospect,
                    controller: controller
                )
                // .navigationTitle("Upcoming Meetings")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showKnocksSheet) {
            NavigationStack {
                ProspectKnockingHistoryView(prospect: prospect)
                    .navigationTitle("Knocking History")
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $controller.showConversionSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Confirm Customer Info")) {
                        TextField("Full Name", text: $prospect.fullName)
                        TextField("Address", text: $prospect.address)
                        TextField("Phone", text: $controller.tempPhone)
                        TextField("Email", text: $controller.tempEmail)
                    }
                    Section {
                        Button("Confirm Sign Up") {
                            controller.convertToCustomer(prospect, modelContext: modelContext)
                            controller.showConversionSheet = false
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(prospect.fullName.isEmpty || prospect.address.isEmpty)
                    }
                }
                .navigationTitle("Convert to Customer")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { controller.showConversionSheet = false }
                    }
                }
            }
        }
    }
    
    private var prospectScorecardItems: [DetailsScorecardItem] {
        [
            DetailsScorecardItem(
                kind: .meetings,
                title: "Meetings",
                value: "\(prospect.appointments.filter { $0.date >= Date() }.count)",
                icon: "calendar.badge.clock",
                color: .blue,
                action: {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    showAppointmentsSheet = true
                }
            ),
            DetailsScorecardItem(
                kind: .knocks,
                title: "Knocks",
                value: "\(prospect.knockHistory.count)",
                icon: "hand.tap.fill",
                color: .orange,
                action: {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    showKnocksSheet = true
                }
            )
        ]
    }

    private func navigateToMap() {
        ContactScreenHapticsController.shared.successConfirmationTap()
        ContactScreenSoundController.shared.playSound1()
        presentationMode.wrappedValue.dismiss()
        onNavigateToMap(
            MapContactSelection(
                contactID: prospect.uuid,
                address: prospect.address,
                list: "Prospects",
                coordinate: prospect.coordinate
            )
        )
    }

    private func showExportPromptAfterOptionsDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showExportPrompt = true
        }
    }

    private func shareProspectAfterOptionsDismiss() {
        let fullName = prospect.fullName
        let address = prospect.address
        let phone = prospect.contactPhone
        let email = prospect.contactEmail

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            contactSharePayload = ContactSharePresenter.payload(
                fullName: fullName,
                address: address,
                phone: phone,
                email: email
            )
        }
    }

    private func exportToContacts() {
        let store = CNContactStore()
        
        // Capture immutable copies of prospect data for thread-safe use in the closure
        let prospectFullName = prospect.fullName
        let prospectAddress = prospect.address
        let prospectPhone = prospect.contactPhone
        let prospectEmail = prospect.contactEmail
        
        store.requestAccess(for: .contacts) { granted, _ in
            guard granted else {
                Task { @MainActor in
                    showExportFeedback("Contacts access denied.")
                }
                return
            }

            let predicate = CNContact.predicateForContacts(matchingName: prospectFullName)
            
            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor
            ]

            do {
                let matches = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
                let existing = matches.first {
                    $0.postalAddresses.first?.value.street == prospectAddress
                }

                let contact: CNMutableContact
                let saveRequest = CNSaveRequest()

                if let existing = existing {
                    contact = existing.mutableCopy() as! CNMutableContact
                    saveRequest.update(contact)
                } else {
                    contact = CNMutableContact()
                    contact.givenName = prospectFullName
                    saveRequest.add(contact, toContainerWithIdentifier: nil)
                }

                if !prospectPhone.isEmpty {
                    contact.phoneNumbers = [
                        CNLabeledValue(
                            label: CNLabelPhoneNumberMobile,
                            value: CNPhoneNumber(stringValue: prospectPhone)
                        )
                    ]
                }

                if !prospectEmail.isEmpty {
                    contact.emailAddresses = [
                        CNLabeledValue(
                            label: CNLabelHome,
                            value: NSString(string: prospectEmail)
                        )
                    ]
                }

                let postal = CNMutablePostalAddress()
                postal.street = prospectAddress
                contact.postalAddresses = [
                    CNLabeledValue(label: CNLabelHome, value: postal)
                ]

                try store.execute(saveRequest)
                
                Task { @MainActor in
                    showExportFeedback("Contact saved to Contacts.")
                }
                
            } catch {
                Task { @MainActor in
                    showExportFeedback("Failed to save contact.")
                }
            }
        }
    }

    private func showExportFeedback(_ message: String) {
        DispatchQueue.main.async {
            exportSuccessMessage = message
            withAnimation {
                showExportSuccessBanner = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showExportSuccessBanner = false
                }
            }
        }
    }
    
    private func revertEdits() {
        withAnimation(.easeInOut(duration: 0.2)) {
            tempFullName = prospect.fullName
            tempAddress = prospect.address
            isAddressFieldFocused = false
            searchViewModel.clear()
        }
    }

    // MARK: - Logic
    private var hasUnsavedEdits: Bool {
        tempFullName.trimmingCharacters(in: .whitespacesAndNewlines) != prospect.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ||
        tempAddress.trimmingCharacters(in: .whitespacesAndNewlines) != prospect.address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isAddressPredictionVisible: Bool {
        isAddressFieldFocused && !searchViewModel.results.isEmpty
    }

    private func acceptBestAddressPredictionIfAvailable() async {
        guard isAddressFieldFocused || !searchViewModel.results.isEmpty else { return }
        guard let resolved = await ContactAddressPredictionController.resolvePrediction(
            typedAddress: tempAddress,
            completions: searchViewModel.results
        ) else { return }

        tempAddress = resolved
        searchViewModel.clear()
        isAddressFieldFocused = false
    }

    private func commitEdits() {
        let trimmedName = tempFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = tempAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        var changeNotes: [String] = []

        // Detect name change
        if trimmedName != prospect.fullName {
            let note = "Name changed from \(prospect.fullName.isEmpty ? "Unknown" : prospect.fullName) to \(trimmedName)."
            changeNotes.append(note)
            prospect.fullName = trimmedName
        }

        // Detect address change
        if trimmedAddress != prospect.address {
            let note = "Address changed from \(prospect.address.isEmpty ? "Unknown" : prospect.address) to \(trimmedAddress)."
            changeNotes.append(note)
            prospect.address = trimmedAddress

            // ✅ Geocode the new address to update latitude/longitude
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmedAddress

            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let coordinate = response?.mapItems.first?.location.coordinate {
                    prospect.latitude = coordinate.latitude
                    prospect.longitude = coordinate.longitude
                    print("📍 Updated prospect coordinates: \(coordinate.latitude), \(coordinate.longitude)")
                } else {
                    print("❌ Failed to geocode address: \(error?.localizedDescription ?? "Unknown error")")
                }

                controller.saveProspect(prospect, modelContext: modelContext)
            }
            
        } else {
            // Save immediately if only the name changed
            controller.saveProspect(prospect, modelContext: modelContext)
        }

        // Append automatic notes (if any)
        for change in changeNotes {
            let autoNote = Note(content: change, date: Date(), prospect: prospect)
            prospect.notes.append(autoNote)
        }
    }
    
}
