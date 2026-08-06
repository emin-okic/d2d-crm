//
//  ScheduleCustomerAppointmentView.swift
//  d2d-studio
//
//  Created by Emin Okic on 10/17/25.
//

import SwiftUI
import SwiftData

struct ScheduleCustomerAppointmentView: View {
    @Environment(\.modelContext) private var context

    let customer: Customer

    var body: some View {
        FollowUpScheduleFormView(
            contactKind: "Customer",
            contactName: customer.fullName,
            contactAddress: customer.address,
            contactNotes: customer.notes
        ) { date, type in
            let appointment = Appointment(
                title: customer.fullName,
                location: customer.address,
                clientName: customer.fullName,
                date: date,
                type: type,
                notes: customer.notes.map { $0.content }
            )

            customer.appointments.append(appointment)
            context.insert(appointment)
            try? context.save()
        }
    }
}
