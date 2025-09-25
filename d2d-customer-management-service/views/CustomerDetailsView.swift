//
//  CustomerDetailsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/25/25.
//

import SwiftUI
import SwiftData

struct CustomerDetailsView: View {
    @Bindable var customer: Customer
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab: CustomerTab = .appointments
    
    var body: some View {
        Form {
            Section(header: Text("Customer Details")) {
                TextField("Full Name", text: $customer.fullName)
                TextField("Address", text: $customer.address)
                TextField("Phone", text: $customer.contactPhone)
                TextField("Email", text: $customer.contactEmail)
            }
            
            Section {
                CustomerActionsToolbar(customer: customer)
            }
            
            Section {
                Picker("View", selection: $selectedTab) {
                    ForEach(CustomerTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom)
                
                // ✅ Now just reference a single computed property
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
    
    // 👇 Computed property handles the switch
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

private struct AppointmentsView: View {
    let customer: Customer
    
    var body: some View {
        let upcomingAppointments = customer.appointments
            .filter { $0.date >= Date() }
            .sorted { $0.date < $1.date }
            .prefix(3)
        
        if upcomingAppointments.isEmpty {
            Text("No upcoming follow-ups.")
                .foregroundColor(.gray)
        } else {
            ForEach(upcomingAppointments) { appt in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Follow Up With \(customer.fullName)")
                        .font(.subheadline).fontWeight(.medium)
                    Text(customer.address).font(.caption).foregroundColor(.gray)
                    Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

enum CustomerTab: String, CaseIterable {
    case appointments = "Appointments"
    case knocks = "Knocks"
    case notes = "Notes"
}
