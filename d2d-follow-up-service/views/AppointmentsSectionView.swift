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
    @Query private var prospects: [Prospect]

    @State private var showingProspectPicker = false
    @State private var selectedProspect: Prospect?
    @State private var selectedAppointment: Appointment?

    @State private var filter: AppointmentFilter = .upcoming
    private let filterKey = "lastSelectedAppointmentFilter"

    private var now: Date { Date() }

    private var upcomingCount: Int {
        appointments.filter { $0.date >= now }.count
    }

    private var pastCount: Int {
        appointments.filter { $0.date < now }.count
    }

    private var filteredAppointments: [Appointment] {
        let ups = appointments.filter { $0.date >= now }.sorted { $0.date < $1.date }
        let past = appointments.filter { $0.date < now }.sorted { $0.date > $1.date }
        return filter == .upcoming ? ups : past
    }

    var body: some View {
        ZStack {
            // CONTENT pinned to top-left
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header row
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Appointments")
                                .font(.headline)
                            Text(filter == .upcoming
                                 ? "\(upcomingCount) Upcoming Appointments"
                                 : "\(pastCount) Past Appointments")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Menu {
                            Picker("Filter", selection: $filter) {
                                ForEach(AppointmentFilter.allCases) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                        }

                        Button {
                            showingProspectPicker = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Empty state (no extra top gap)
                    if filteredAppointments.isEmpty {
                        Text("No \(filter.rawValue.lowercased()) appointments.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    } else {
                        // List replacement: tight, top-pinned, no auto insets
                        LazyVStack(spacing: 0) {
                            ForEach(filteredAppointments) { appointment in
                                Button {
                                    selectedAppointment = appointment
                                } label: {
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
                                Divider()
                                    .padding(.leading, 20)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, 12)
            }
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
        // Sheets
        .sheet(isPresented: $showingProspectPicker) {
            NavigationStack {
                List(prospects) { prospect in
                    Button {
                        selectedProspect = prospect
                        showingProspectPicker = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prospect.fullName)
                            Text(prospect.address)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                    }
                }
                .navigationTitle("Pick Prospect")
                .listStyle(.plain)
            }
        }
        .sheet(item: $selectedProspect) { prospect in
            ScheduleAppointmentView(prospect: prospect)
        }
        .sheet(item: $selectedAppointment) { appt in
            AppointmentDetailsView(appointment: appt)
        }
    }
}
