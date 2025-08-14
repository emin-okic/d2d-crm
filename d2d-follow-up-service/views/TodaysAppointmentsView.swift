//
//  TodaysAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/13/25.
//

import SwiftUI
import SwiftData

struct TodaysAppointmentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appointments: [Appointment]
    @Query private var prospects: [Prospect]

    @State private var selectedAppointment: Appointment?
    @State private var showingProspectPicker = false
    @State private var prospectForToday: Prospect?

    private var todaysAppointments: [Appointment] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return appointments
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        ZStack {
            Group {
                if todaysAppointments.isEmpty {
                    Text("No appointments scheduled for today.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                } else {
                    List(todaysAppointments) { appointment in
                        Button { selectedAppointment = appointment } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Follow Up With \(appointment.prospect?.fullName ?? appointment.title)")
                                    .font(.subheadline).fontWeight(.medium)
                                Text(appointment.prospect?.address ?? "")
                                    .font(.caption).foregroundColor(.gray)
                                Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                    .padding(.horizontal, 20)
                }
            }

            // ⬇️ Bottom-left "+" button (mirrors map toolbar spacing)
            VStack(spacing: 10) {
                Button {
                    showingProspectPicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }
            }
            .padding(.bottom, 30)
            .padding(.leading, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .zIndex(999)
        }
        // Existing sheets
        .sheet(item: $selectedAppointment) { appt in
            AppointmentDetailsView(appointment: appt)
        }
        // Prospect picker for "today" scheduling
        .sheet(isPresented: $showingProspectPicker) {
            NavigationStack {
                List(prospects) { prospect in
                    Button {
                        prospectForToday = prospect
                        showingProspectPicker = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prospect.fullName)
                            Text(prospect.address).font(.caption).foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                    }
                }
                .navigationTitle("Pick Prospect")
                .listStyle(.plain)
            }
        }
        // Launch scheduler with default date = today
        .sheet(item: $prospectForToday) { p in
            // See change #2 below to support defaultDate:
            ScheduleAppointmentView(prospect: p, defaultDate: Date())
        }
    }
}
