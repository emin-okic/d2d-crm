//
//  EditProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData
import PhoneNumberKit
import Contacts
import MapKit

/// A view for editing the details of an existing `Prospect`.
///
/// This form allows users to:
/// - Update the prospect’s full name and address
/// - Reassign the prospect to a different list (e.g., "Customers")
/// - View the full knock history of the prospect
struct ProspectDetailsView: View {
    /// The prospect instance to be edited, bound to the form fields.
    @Bindable var prospect: Prospect
    
    /// Used to dismiss the view when editing is finished.
    @Environment(\.presentationMode) var presentationMode

    /// Predefined list categories a prospect can belong to.
    let allLists = ["Prospects", "Customers"]
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var showKnockHistory = false
    @State private var showNotes = false
    
    @State private var showConversionSheet = false
    @State private var tempPhone: String = ""
    @State private var tempEmail: String = ""
    
    @State private var phoneError: String?
    
    @StateObject private var searchViewModel = SearchCompleterViewModel()
    @FocusState private var isAddressFieldFocused: Bool
    
    @State private var showAppointmentSheet = false

    var body: some View {
        Form {
            // MARK: - Prospect Info Section
            Section(header: Text("Prospect Details")) {
                TextField("Full Name", text: $prospect.fullName)
                
                // Address with auto suggest
                VStack(alignment: .leading, spacing: 0) {
                    TextField("Address", text: $prospect.address)
                        .focused($isAddressFieldFocused)
                        .onChange(of: prospect.address) { newValue in
                            searchViewModel.updateQuery(newValue)
                        }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)

                    if isAddressFieldFocused && !searchViewModel.results.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(searchViewModel.results.prefix(3), id: \.self) { result in
                                Button {
                                    // Perform lookup and assign formatted address
                                    fetchAddress(for: result)
                                    isAddressFieldFocused = false
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.title)
                                            .font(.body)
                                            .bold()
                                            .lineLimit(1)

                                        Text(result.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    .padding()
                                }
                                .buttonStyle(.plain)

                                Divider()
                            }
                        }
                        .background(Color(.systemBackground))
                    }
                }
                
            }
            
            Section {
                   ProspectActionsToolbar(prospect: prospect)
               }
            
            // Appointments Section
            Section(header: Text("Appointments")) {
                let upcomingAppointments = prospect.appointments
                    .filter { $0.date >= Date() }
                    .sorted { $0.date < $1.date }
                    .prefix(3)

                if upcomingAppointments.isEmpty {
                    Text("No upcoming follow-ups.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(upcomingAppointments) { appt in
                        Text(appt.title + " at " + appt.date.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                Button {
                    showAppointmentSheet = true
                } label: {
                    Label("Add Appointment", systemImage: "calendar.badge.plus")
                }
            }

            // MARK: - Knock History Section (Expandable)
            Section {
                DisclosureGroup(isExpanded: $showKnockHistory) {
                    KnockingHistoryView(prospect: prospect)
                } label: {
                    Text("Knock History")
                        .fontWeight(.semibold)
                }
            }

            // MARK: - Notes Section (Expandable)
            Section {
                DisclosureGroup(isExpanded: $showNotes) {
                    let sortedNotes = prospect.notes.sorted { a, b in
                        a.date > b.date
                    }

                    ForEach(sortedNotes, id: \.date) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.content)
                                .font(.body)
                            Text("— \(note.date.formatted(.dateTime.month().day().hour().minute()))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }

                    AddNoteView(prospect: prospect)
                } label: {
                    Text("Notes")
                        .fontWeight(.semibold)
                }
            }
            
        }
        .navigationTitle("Edit Contact")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    if validatePhoneNumber() {
                        prospect.contactPhone = tempPhone
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            tempPhone = prospect.contactPhone
        }
        .sheet(isPresented: $showConversionSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Confirm Customer Info")) {
                        TextField("Full Name", text: $prospect.fullName)
                        TextField("Address", text: $prospect.address)
                        TextField("Phone", text: $tempPhone)
                        TextField("Email", text: $tempEmail)
                    }

                    Section {
                        Button("Confirm Sign Up") {
                            prospect.list = "Customers"
                            prospect.contactPhone = tempPhone
                            prospect.contactEmail = tempEmail
                            try? modelContext.save()
                            showConversionSheet = false
                            presentationMode.wrappedValue.dismiss()
                        }
                        .disabled(prospect.fullName.isEmpty || prospect.address.isEmpty)
                    }
                }
                .navigationTitle("Convert to Customer")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showConversionSheet = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAppointmentSheet) {
            NavigationStack {
                ScheduleAppointmentView(prospect: prospect)
            }
        }
    }
    
    private func fetchAddress(for completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let item = response?.mapItems.first {
                // Use formatted full postal address
                let postalAddress = item.placemark.postalAddress
                if let postalAddress {
                    let formatter = CNPostalAddressFormatter()
                    let fullAddress = formatter.string(from: postalAddress).replacingOccurrences(of: "\n", with: ", ")
                    prospect.address = fullAddress
                } else {
                    // Fallback to name or title
                    prospect.address = item.name ?? completion.title
                }
            }
        }
    }
    
    private func exportToContacts() {
        let contact = CNMutableContact()
        contact.givenName = prospect.fullName
        contact.phoneNumbers = [CNLabeledValue(
            label: CNLabelPhoneNumberMobile,
            value: CNPhoneNumber(stringValue: prospect.contactPhone)
        )]

        contact.emailAddresses = [CNLabeledValue(
            label: CNLabelHome,
            value: NSString(string: prospect.contactEmail)
        )]

        let postal = CNMutablePostalAddress()
        postal.street = prospect.address
        contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: postal)]

        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)

        do {
            let store = CNContactStore()
            try store.requestAccess(for: .contacts) { granted, error in
                if granted {
                    do {
                        try store.execute(saveRequest)
                        print("✅ Contact saved")
                    } catch {
                        print("❌ Failed to save contact: \(error)")
                    }
                } else {
                    print("❌ Access to contacts denied")
                }
            }
        }
    }
    
    @discardableResult
    private func validatePhoneNumber() -> Bool {
        let raw = tempPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            phoneError = nil
            return true
        }

        let utility = PhoneNumberUtility()  // correct class in v4
        do {
            _ = try utility.parse(raw)       // parse + validation
            phoneError = nil
            return true
        } catch {
            phoneError = "Invalid phone number."
            return false
        }
    }
    
    private func deleteProspect() {
        // 1. Delete the prospect from SwiftData
        modelContext.delete(prospect)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete prospect from SwiftData: \(error)")
        }

        // 2. Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
}

extension CNPostalAddress {
    func apply(_ modify: (inout CNPostalAddress) -> Void) -> CNPostalAddress {
        var copy = self
        modify(&copy)
        return copy
    }
}
