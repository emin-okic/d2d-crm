//
//  EditProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData

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

    var body: some View {
        Form {
            // MARK: - Prospect Info Section
            Section(header: Text("Prospect Details")) {
                TextField("Full Name", text: $prospect.fullName)
                TextField("Address", text: $prospect.address)
                TextField("Phone", text: $prospect.contactPhone)
                TextField("Email", text: $prospect.contactEmail)
            }
            
            // Appointments Section
            Section(header: Text("Appointments")) {
                let upcomingAppointments = prospect.appointments
                    .filter { $0.date >= Date() }
                    .sorted { $0.date < $1.date }
                    .prefix(3) // Show at most 3

                if upcomingAppointments.isEmpty {
                    Text("No upcoming follow-ups.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(upcomingAppointments) { appt in
                        Text(appt.title + " at " + appt.date.formatted(date: .abbreviated, time: .shortened))
                    }
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
            
            if prospect.list == "Prospects" {
                Section {
                    Button("Sign Up") {
                        tempPhone = prospect.contactPhone
                        tempEmail = prospect.contactEmail
                        showConversionSheet = true
                    }
                    .foregroundColor(.blue)
                }
                Section {

                    Button("Delete Prospect 🗑️") {
                        deleteProspect()
                    }
                    .foregroundColor(.red)
                    
                }
            }
            
            if prospect.list == "Customers" {
                Section {

                    Button("Delete Customer 🗑️") {
                        deleteProspect()
                    }
                    .foregroundColor(.red)
                    
                }
            }
        }
        .navigationTitle("Edit Contact")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
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
