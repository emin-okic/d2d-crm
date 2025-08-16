//
//  TodaysAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/13/25.
//

import SwiftUI
import SwiftData
import MapKit

struct TodaysAppointmentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appointments: [Appointment]
    @Query private var prospects: [Prospect]

    @State private var selectedAppointment: Appointment?
    @State private var showingProspectPicker = false
    @State private var prospectForToday: Prospect?

    // ✅ Feedback banner (reuse your pattern)
    @State private var showBanner = false
    @State private var bannerMessage = ""

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
                                Text(appointment.prospect?.address ?? appointment.location)
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

            // ⬅️ Bottom-left toolbar (stacked)
            VStack(spacing: 12) {
                // Add Trip button
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

                // Car button (blue, stacked below)
                Button {
                    Task {
                        if todaysUpcomingCount == 0 {
                            show("No upcoming appointments left today.")
                            return
                        }
                        await RoutePlannerController.planAndOpenTodaysRoute(
                            appointments: todaysAppointments,
                            modelContext: modelContext
                        )
                        show("Opened route in Apple Maps and logged trip.")
                    }
                } label: {
                    Image(systemName: "car.fill")
                        .font(.system(size: 22, weight: .semibold))
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

            // ✅ Banner
            if showBanner {
                VStack {
                    Spacer().frame(height: 60)
                    Text(bannerMessage)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.95))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .zIndex(1000)
            }
        }
        .sheet(item: $selectedAppointment) { appt in
            AppointmentDetailsView(appointment: appt)
        }
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
        .sheet(item: $prospectForToday) { p in
            ScheduleAppointmentView(prospect: p, defaultDate: Date())
        }
    }

    private var todaysUpcomingCount: Int {
        let now = Date()
        return todaysAppointments.filter { $0.date >= now }.count
    }

    private func show(_ message: String) {
        bannerMessage = message
        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showBanner = false }
        }
    }
}
