//
//  EditProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData

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

    var body: some View {
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
                    KnockingHistoryView(prospect: prospect)

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

            // Share Button (always visible)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    controller.shareProspect(prospect)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }

            // Save Button (only appears if name/address changed)
            if hasUnsavedEdits {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            commitEdits()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
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
            let oldAddress = prospect.address
            let note = "Address changed from \(prospect.address.isEmpty ? "Unknown" : prospect.address) to \(trimmedAddress)."
            changeNotes.append(note)
            prospect.address = trimmedAddress

            Task { @MainActor in
                await controller.updateCoordinatesIfAddressChanged(
                    prospect,
                    oldAddress: oldAddress,
                    modelContext: modelContext
                )
            }
        }

        // Append automatic notes (if any)
        for change in changeNotes {
            let autoNote = Note(content: change, date: Date(), prospect: prospect)
            prospect.notes.append(autoNote)
        }

        // Save prospect + notes
        controller.saveProspect(prospect, modelContext: modelContext)
    }
    
}

enum ProspectTab: String, CaseIterable {
    case appointments = "Appointments"
    case knocks = "Knocks"
    case notes = "Notes"
}
