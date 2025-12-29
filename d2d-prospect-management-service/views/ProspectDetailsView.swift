//
//  EditProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData
import CoreLocation
import Contacts

struct ProspectDetailsView: View {
    @Bindable var prospect: Prospect
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext

    @StateObject private var controller = ProspectController()
    @StateObject private var searchViewModel = SearchCompleterViewModel()
    @FocusState private var isAddressFieldFocused: Bool

    // 🔑 Local editable copies for deferred saving
    @State private var tempFullName: String = ""
    @State private var tempAddress: String = ""
    
    @State private var showDeleteConfirmation = false
    
    @State private var showRevertConfirmation = false
    
    @State private var actionsToolbarProxy: ProspectActionsToolbar?
    
    @State private var showExportPrompt = false
    @State private var showExportSuccessBanner = false
    @State private var exportSuccessMessage = ""
    
    @State private var showDemographicsEditor = false

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
                // Prospect info
                Section(header: Text("Prospect Details")) {
                    TextField("Full Name", text: $tempFullName)
                    
                    // Address with autocomplete
                    AddressAutocompleteField(
                        addressText: $tempAddress,
                        isFocused: $isAddressFieldFocused,
                        searchViewModel: searchViewModel
                    )
                }
                
                // ✅ Actions Toolbar (unchanged)
                Section {
                    ProspectActionsToolbar(prospect: prospect)
                }
                
                // Tabs for Appointments / Knocks / Notes
                Section {
                    Picker("View", selection: $controller.selectedTab) {
                        ForEach(ProspectTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 6)
                    
                    switch controller.selectedTab {
                    case .appointments:
                        let upcoming = prospect.appointments
                            .filter { $0.date >= Date() }
                            .sorted { $0.date < $1.date }
                            .prefix(3)
                        
                        if upcoming.isEmpty {
                            Text("No upcoming follow-ups.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(upcoming) { appt in
                                Button {
                                    controller.selectedAppointmentDetails = appt
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Follow Up With \(prospect.fullName)")
                                            .font(.subheadline).fontWeight(.medium)
                                        Text(prospect.address)
                                            .font(.caption).foregroundColor(.gray)
                                        Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption).foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Button {
                            controller.showAppointmentSheet = true
                        } label: {
                            Label("Add Appointment", systemImage: "calendar.badge.plus")
                        }
                        
                    case .knocks:
                        ProspectKnockingHistoryView(prospect: prospect)
                        
                    case .notes:
                        NotesThreadSection(
                            prospect: prospect,
                            maxHeight: 180,
                            maxVisibleNotes: 3,
                            showChips: false
                        )
                    }
                }
            }
            
            // Bottom-left floating buttons
            HStack {
                VStack(spacing: 16) { // stack vertically with some spacing
                    // Demographics button
                    Button(action: {
                        if prospect.demographics == nil {
                            prospect.demographics = Demographics()
                        }
                        showDemographicsEditor = true
                    }) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .sheet(isPresented: $showDemographicsEditor) {
                        DemographicsEditorView(demographics: Binding(
                            get: { prospect.demographics! },
                            set: { prospect.demographics = $0 }
                        ))
                    }

                    // Delete button
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding()
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .sheet(isPresented: $showDeleteConfirmation) {
                        DeleteProspectSheet(
                            prospectName: prospect.fullName,
                            onDelete: deleteProspect
                        )
                        .presentationDetents([.fraction(0.25)])
                        .presentationDragIndicator(.visible)
                    }
                }
                .padding(.leading, 16)
                .padding(.bottom, 16)

                Spacer() // push everything to the left
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .navigationTitle("Edit Contact")
        .toolbar {
            // Back Button
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
            
            // Export + Share (hidden while editing)
            if !hasUnsavedEdits {
                ToolbarItemGroup(placement: .navigationBarTrailing) {

                    // ✅ Export to Contacts
                    Button {
                        showExportPrompt = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }

                    // Share
                    Button {
                        controller.shareProspect(prospect)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }

            // Save Button (only appears if name/address changed)
            if hasUnsavedEdits {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Revert") {
                        showRevertConfirmation = true
                    }
                    .foregroundColor(.red)

                    Button("Save") {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            commitEdits()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
        }
        .alert("Export to Contacts", isPresented: $showExportPrompt) {
            Button("Yes") {
                exportToContacts()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to save this contact to your iOS Contacts app?")
        }
        .alert("Revert Changes?", isPresented: $showRevertConfirmation) {
            Button("Revert Changes", role: .destructive) {
                revertEdits()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will discard all unsaved changes and restore the original prospect details.")
        }
        .onAppear {
            controller.captureBaseline(from: prospect)
            // Initialize local edit copies
            tempFullName = prospect.fullName
            tempAddress = prospect.address
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
        .sheet(isPresented: $controller.showAppointmentSheet) {
            NavigationStack {
                ScheduleAppointmentView(prospect: prospect)
            }
        }
        .sheet(item: $controller.selectedAppointmentDetails) { appointment in
            AppointmentDetailsView(appointment: appointment)
        }
    }
    
    private func exportToContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            guard granted else {
                showExportFeedback("Contacts access denied.")
                return
            }

            let predicate = CNContact.predicateForContacts(matchingName: prospect.fullName)
            
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
                    $0.postalAddresses.first?.value.street == prospect.address
                }

                let contact: CNMutableContact
                let saveRequest = CNSaveRequest()

                if let existing = existing {
                    contact = existing.mutableCopy() as! CNMutableContact
                    saveRequest.update(contact)
                } else {
                    contact = CNMutableContact()
                    contact.givenName = prospect.fullName
                    saveRequest.add(contact, toContainerWithIdentifier: nil)
                }

                if !prospect.contactPhone.isEmpty {
                    contact.phoneNumbers = [
                        CNLabeledValue(
                            label: CNLabelPhoneNumberMobile,
                            value: CNPhoneNumber(stringValue: prospect.contactPhone)
                        )
                    ]
                }

                if !prospect.contactEmail.isEmpty {
                    contact.emailAddresses = [
                        CNLabeledValue(
                            label: CNLabelHome,
                            value: NSString(string: prospect.contactEmail)
                        )
                    ]
                }

                let postal = CNMutablePostalAddress()
                postal.street = prospect.address
                contact.postalAddresses = [
                    CNLabeledValue(label: CNLabelHome, value: postal)
                ]

                try store.execute(saveRequest)
                showExportFeedback("Contact saved to Contacts.")
            } catch {
                showExportFeedback("Failed to save contact.")
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
        }
    }
    
    // MARK: - Delete customer and their appointments
    private func deleteProspect() {
        for appointment in prospect.appointments {
            modelContext.delete(appointment)
        }
        modelContext.delete(prospect)
        try? modelContext.save()
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.dismiss(animated: true)
            }
        }
    }
    
    private func deleteProspectAndAppointments() {
        // Delete all appointments linked to the prospect
        for appointment in prospect.appointments {
            modelContext.delete(appointment)
        }

        // Now delete the prospect itself
        modelContext.delete(prospect)

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to delete prospect or appointments: \(error)")
        }

    }

    // MARK: - Logic
    private var hasUnsavedEdits: Bool {
        tempFullName.trimmingCharacters(in: .whitespacesAndNewlines) != prospect.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ||
        tempAddress.trimmingCharacters(in: .whitespacesAndNewlines) != prospect.address.trimmingCharacters(in: .whitespacesAndNewlines)
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
            CLGeocoder().geocodeAddressString(trimmedAddress) { placemarks, error in
                if let coord = placemarks?.first?.location?.coordinate {
                    prospect.latitude = coord.latitude
                    prospect.longitude = coord.longitude
                    print("📍 Updated prospect coordinates: \(coord.latitude), \(coord.longitude)")
                } else {
                    print("❌ Failed to geocode address: \(error?.localizedDescription ?? "Unknown error")")
                }

                // Save prospect + notes after geocoding
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

enum ProspectTab: String, CaseIterable {
    case appointments = "Appointments"
    case knocks = "Knocks"
    case notes = "Notes"
}
