//
//  CustomerDetailsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//

import SwiftUI
import SwiftData
import MapKit
import Contacts

@available(iOS 18.0, *)
struct CustomerDetailsView: View {
    @Bindable var customer: Customer
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: CustomerTab = .appointments

    // Local editable copies
    @State private var tempFullName: String = ""
    @State private var tempAddress: String = ""

    // For address autocomplete
    @StateObject private var searchViewModel = SearchCompleterViewModel()
    @FocusState private var isAddressFieldFocused: Bool
    
    @State private var showDeleteConfirmation = false

    // Detect unsaved edits
    private var hasUnsavedEdits: Bool {
        tempFullName.trimmingCharacters(in: .whitespacesAndNewlines) != customer.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ||
        tempAddress.trimmingCharacters(in: .whitespacesAndNewlines) != customer.address.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @State private var showRevertConfirmation = false
    
    @State private var showExportPrompt = false
    @State private var showExportSuccessBanner = false
    @State private var exportSuccessMessage = ""

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
                // ✅ Customer core info
                Section(header: Text("Customer Details")) {
                    TextField("Full Name", text: $tempFullName)
                    
                    // 👇 Autocomplete-enabled address field
                    AddressAutocompleteField(
                        addressText: $tempAddress,
                        isFocused: $isAddressFieldFocused,
                        searchViewModel: searchViewModel
                    )
                }
                
                // ✅ Actions Toolbar
                Section {
                    CustomerActionsToolbar(customer: customer)
                }
                
                // ✅ Tabs (Appointments, Knocks, Notes)
                Section {
                    Picker("View", selection: $selectedTab) {
                        ForEach(CustomerTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom)
                    
                    tabContent
                }
            }
            
            // Bottom-left floating delete button
            VStack {
                Spacer()
                HStack {
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
                    .padding(.leading, 16)
                    Spacer()
                }
            }
            .sheet(isPresented: $showDeleteConfirmation) {
                DeleteCustomerSheet(
                    customerName: customer.fullName,
                    onDelete: deleteCustomer
                )
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
            }
            
        }
        .navigationTitle("Customer Details")
        .toolbar {
            // Back Button
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
            
            if !hasUnsavedEdits {
                ToolbarItemGroup(placement: .navigationBarTrailing) {

                    Button {
                        showExportPrompt = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }
                }
            }

            // Revert + Save (only when editing)
            if hasUnsavedEdits {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Revert") {
                        showRevertConfirmation = true
                    }
                    .foregroundColor(.red)

                    Button("Save") {
                        commitEdits()
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
            Text("This will discard all unsaved changes and restore the original customer details.")
        }
        .onAppear {
            tempFullName = customer.fullName
            tempAddress = customer.address
        }
    }
    
    private func exportToContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            guard granted else {
                showExportFeedback("Contacts access denied.")
                return
            }

            let predicate = CNContact.predicateForContacts(matchingName: customer.fullName)
            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor
            ]

            do {
                let matches = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
                let existing = matches.first {
                    $0.postalAddresses.first?.value.street == customer.address
                }

                let contact: CNMutableContact
                let saveRequest = CNSaveRequest()

                if let existing = existing {
                    contact = existing.mutableCopy() as! CNMutableContact
                    saveRequest.update(contact)
                } else {
                    contact = CNMutableContact()
                    contact.givenName = customer.fullName
                    saveRequest.add(contact, toContainerWithIdentifier: nil)
                }

                if !customer.contactPhone.isEmpty {
                    contact.phoneNumbers = [
                        CNLabeledValue(
                            label: CNLabelPhoneNumberMobile,
                            value: CNPhoneNumber(stringValue: customer.contactPhone)
                        )
                    ]
                }

                if !customer.contactEmail.isEmpty {
                    contact.emailAddresses = [
                        CNLabeledValue(
                            label: CNLabelHome,
                            value: NSString(string: customer.contactEmail)
                        )
                    ]
                }

                let postal = CNMutablePostalAddress()
                postal.street = customer.address
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
            tempFullName = customer.fullName
            tempAddress = customer.address
            isAddressFieldFocused = false
        }
    }
    
    private func deleteCustomer() {
        // ✅ Delete all appointments belonging to this customer
        for appointment in customer.appointments {
            modelContext.delete(appointment)
        }

        // ✅ Delete the customer itself
        modelContext.delete(customer)
        try? modelContext.save()

        // ✅ Dismiss the details view
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.dismiss(animated: true)
            }
        }
    }

    // MARK: - Logic
    private func commitEdits() {
        
        let trimmedName = tempFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = tempAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var changeNotes: [String] = []

        if trimmedName != customer.fullName {
            let note = "Name changed from \(customer.fullName.isEmpty ? "Unknown" : customer.fullName) to \(trimmedName)."
            changeNotes.append(note)
            customer.fullName = trimmedName
        }

        // Address change
        if trimmedAddress != customer.address {
            let note = "Address changed from \(customer.address.isEmpty ? "Unknown" : customer.address) to \(trimmedAddress)."
            changeNotes.append(note)
            customer.address = trimmedAddress

            // ✅ Re-geocode address
            CLGeocoder().geocodeAddressString(trimmedAddress) { placemarks, error in
                if let coord = placemarks?.first?.location?.coordinate {
                    customer.latitude = coord.latitude
                    customer.longitude = coord.longitude

                    print("📍 Updated customer coordinates:")
                    print("   → Latitude: \(coord.latitude)")
                    print("   → Longitude: \(coord.longitude)")
                } else {
                    print("❌ Failed to geocode customer address:")
                    print("   → \(error?.localizedDescription ?? "Unknown error")")
                }

                // Save AFTER geocoding
                saveCustomer(changeNotes: changeNotes)
            }
        } else {
            // No address change → save immediately
            saveCustomer(changeNotes: changeNotes)
        }

    }
    
    /// This replaces modelContext.save() with an async approach for geocoding lat/long coordinates
    private func saveCustomer(changeNotes: [String]) {
        for note in changeNotes {
            customer.notes.append(
                Note(content: note, date: Date())
            )
        }

        do {
            try modelContext.save()
            print("✅ Customer saved successfully")
        } catch {
            print("❌ Failed to save customer: \(error)")
        }
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .appointments:
            AppointmentsView(customer: customer)
        case .knocks:
            CustomerKnockingHistoryView(customer: customer)
        case .notes:
            CustomerNotesThreadSection(
                customer: customer,
                maxHeight: 180,
                maxVisibleNotes: 3,
                showChips: false
            )
        }
    }
}

// MARK: - Subviews

private struct AppointmentsView: View {
    @Bindable var customer: Customer
    @Environment(\.modelContext) private var modelContext
    @State private var showAppointmentSheet = false
    @State private var selectedAppointment: Appointment?

    var body: some View {
        // sort by date like Prospect version
        let upcoming = customer.appointments
            .filter { $0.date >= Date() }
            .sorted { $0.date < $1.date }

        VStack(alignment: .leading, spacing: 8) {
            if upcoming.isEmpty {
                Text("No upcoming follow-ups.")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(upcoming) { appt in
                        Button {
                            selectedAppointment = appt
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Follow Up With \(customer.fullName)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(customer.address)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }
                }
            }

            Button {
                showAppointmentSheet = true
            } label: {
                Label("Add Appointment", systemImage: "calendar.badge.plus")
                    .font(.subheadline)
            }
            .padding(.top, 6)
        }
        // ✅ padding gives breathing room like Prospect view
        .padding(.vertical, 4)
        .sheet(isPresented: $showAppointmentSheet) {
            NavigationStack {
                ScheduleCustomerAppointmentView(customer: customer)
            }
        }
        .sheet(item: $selectedAppointment) { appointment in
            AppointmentDetailsView(appointment: appointment)
        }
    }
}

enum CustomerTab: String, CaseIterable {
    case appointments = "Appointments"
    case knocks = "Knocks"
    case notes = "Notes"
}
