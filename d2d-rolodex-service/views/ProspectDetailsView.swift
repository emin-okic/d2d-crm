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
    
    // Sheet for adding a new appointment
    @State private var showAppointmentSheet = false
    // Track which existing appointment to view details for
    @State private var selectedAppointmentDetails: Appointment?
    
    @State private var selectedTab: ProspectTab = .appointments

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
            
            Section {
                Picker("View", selection: $selectedTab) {
                    ForEach(ProspectTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom)

                switch selectedTab {
                case .appointments:
                    let upcomingAppointments = prospect.appointments
                        .filter { $0.date >= Date() }
                        .sorted { $0.date < $1.date }
                        .prefix(3)

                    if upcomingAppointments.isEmpty {
                        Text("No upcoming follow-ups.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(upcomingAppointments) { appt in
                            Button {
                                selectedAppointmentDetails = appt
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Follow Up With \(prospect.fullName)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text(prospect.address)
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        showAppointmentSheet = true
                    } label: {
                        Label("Add Appointment", systemImage: "calendar.badge.plus")
                    }

                case .knocks:
                    KnockingHistoryView(prospect: prospect)

                case .notes:
                    NotesThreadSection(prospect: prospect, maxHeight: 180, maxVisibleNotes: 3, showChips: false)
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
        // Sheet for conversion to customer
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
        // Sheet for adding a new appointment
        .sheet(isPresented: $showAppointmentSheet) {
            NavigationStack {
                ScheduleAppointmentView(prospect: prospect)
            }
        }
        // Sheet for viewing appointment details
        .sheet(item: $selectedAppointmentDetails) { appointment in
            AppointmentDetailsView(appointment: appointment)
        }
    }
    
    private func fetchAddress(for completion: MKLocalSearchCompletion) {
        Task {
            if let fullAddress = await SearchBarController.resolveFormattedPostalAddress(from: completion) {
                prospect.address = fullAddress
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

        let utility = PhoneNumberUtility()
        do {
            _ = try utility.parse(raw)
            phoneError = nil
            return true
        } catch {
            phoneError = "Invalid phone number."
            return false
        }
    }
    
}

enum ProspectTab: String, CaseIterable {
    case appointments = "Appointments"
    case knocks = "Knocks"
    case notes = "Notes"
}
