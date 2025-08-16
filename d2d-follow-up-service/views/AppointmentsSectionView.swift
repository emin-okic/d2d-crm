//
//  AppointmentsSectionView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//
import SwiftUI
import SwiftData

struct AppointmentsSectionView: View {
    @Query private var appointments: [Appointment]
    @Query private var prospects: [Prospect]   // can stay (not used here now, but harmless)

    // Removed: showingProspectPicker / selectedProspect
    @State private var selectedAppointment: Appointment?

    @State private var filter: AppointmentFilter = .upcoming
    private let filterKey = "lastSelectedAppointmentFilter"

    private var now: Date { Date() }

    private var upcomingCount: Int { appointments.filter { $0.date >= now }.count }
    private var pastCount: Int { appointments.filter { $0.date <  now }.count }

    private var filteredAppointments: [Appointment] {
        let ups  = appointments.filter { $0.date >= now }.sorted { $0.date < $1.date }
        let past = appointments.filter { $0.date <  now }.sorted { $0.date > $1.date }
        return filter == .upcoming ? ups : past
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Appointments")
                            .font(.headline)
                        Text(filter == .upcoming
                             ? "\(upcomingCount) Upcoming Appointments"
                             : "\(pastCount) Past Appointments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Toggle chips
                    HStack(spacing: 8) {
                        toggleChip("Upcoming", isOn: filter == .upcoming) { filter = .upcoming }
                        toggleChip("Past",     isOn: filter == .past)     { filter = .past }
                    }
                    .padding(.horizontal, 20)

                    // Empty / list
                    if filteredAppointments.isEmpty {
                        Text("No \(filter.rawValue.lowercased()) appointments.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredAppointments) { appointment in
                                Button { selectedAppointment = appointment } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Follow Up With \(appointment.prospect?.fullName ?? appointment.title)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Text(appointment.prospect?.address ?? appointment.location)
                                            .font(.caption)
                                            .foregroundColor(.gray)

                                        Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                Divider().padding(.leading, 20)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.automatic)
        }
        .onAppear {
            if let saved = UserDefaults.standard.string(forKey: filterKey),
               let parsed = AppointmentFilter(rawValue: saved) {
                filter = parsed
            } else {
                filter = .upcoming
            }
        }
        .onChange(of: filter) {
            UserDefaults.standard.set(filter.rawValue, forKey: filterKey)
        }
        // Only appointment details sheet remains here
        .sheet(item: $selectedAppointment) { appt in
            AppointmentDetailsView(appointment: appt)
        }
    }

    @ViewBuilder
    private func toggleChip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .frame(minWidth: 72)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isOn ? Color.blue : Color(.secondarySystemBackground))
                )
                .foregroundColor(isOn ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOn ? Color.blue.opacity(0.9) : Color.gray.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
}
