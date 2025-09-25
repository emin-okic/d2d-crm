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
    
    let allLists = ["Prospects", "Customers"]
    
    var body: some View {
        Form {
            // Prospect info
            Section(header: Text("Prospect Details")) {
                TextField("Full Name", text: $prospect.fullName)
                
                // Address field with auto-complete
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
                                    controller.fetchAddress(for: result, prospect: prospect)
                                    isAddressFieldFocused = false
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.title).font(.body).bold().lineLimit(1)
                                        Text(result.subtitle).font(.subheadline).foregroundColor(.gray).lineLimit(1)
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
            
            // Actions
            Section {
                ProspectActionsToolbar(prospect: prospect)
            }
            
            // Tabs
            Section {
                Picker("View", selection: $controller.selectedTab) {
                    ForEach(ProspectTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom)
                
                switch controller.selectedTab {
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
                                controller.selectedAppointmentDetails = appt
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Follow Up With \(prospect.fullName)")
                                        .font(.subheadline).fontWeight(.medium)
                                    Text(prospect.address).font(.caption).foregroundColor(.gray)
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
                    NotesThreadSection(prospect: prospect, maxHeight: 180, maxVisibleNotes: 3, showChips: false)
                }
            }
        }
        .navigationTitle("Edit Contact")
        .toolbar {
            if controller.isDirty(prospect: prospect) {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        controller.saveProspect(prospect, modelContext: modelContext)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    controller.shareProspect(prospect)
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            controller.captureBaseline(from: prospect)
        }
        // Sheets
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
}

enum ProspectTab: String, CaseIterable {
    case appointments = "Appointments"
    case knocks = "Knocks"
    case notes = "Notes"
}
