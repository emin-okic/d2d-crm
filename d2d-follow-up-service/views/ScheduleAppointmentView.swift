//
//  ScheduleAppointmentView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//

import SwiftUI
import SwiftData

struct ScheduleAppointmentView: View {
    @Environment(\.modelContext) private var context

    let prospect: Prospect
    var defaultDate: Date? = nil

    var body: some View {
        FollowUpScheduleFormView(
            contactKind: "Prospect",
            contactName: prospect.fullName,
            contactAddress: prospect.address,
            contactNotes: prospect.notes,
            initialDate: defaultDate ?? Date()
        ) { date, type in
            let appointment = Appointment(
                title: type,
                location: prospect.address,
                clientName: prospect.fullName,
                date: date,
                type: type,
                notes: prospect.notes.map { $0.content },
                prospect: prospect
            )
            context.insert(appointment)
            try? context.save()
        }
    }
}
