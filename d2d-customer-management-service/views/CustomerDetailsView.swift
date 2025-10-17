//
//  CustomerDetailsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//

import SwiftUI
import SwiftData

struct CustomerDetailsView: View {
    @Bindable var customer: Customer
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: CustomerTab = .appointments

    var body: some View {
        Form {
            // ✅ Customer core info
            Section(header: Text("Customer Details")) {
                
                TextField("Full Name", text: $customer.fullName)
                
                TextField("Address", text: $customer.address)
            }

            // ✅ Toolbar without "Convert to Sale"
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
        .navigationTitle("Customer Details")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    try? modelContext.save()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    // 👇 Switch between tab content
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
