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

    private var filteredAppointments: [Appointment] {
        let now = Date()
        return appointments
            .filter {
                switch filter {
                case .upcoming:
                    return $0.date >= now
                case .past:
                    return $0.date < now
                }
            }
            .sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Appointments")
                    .font(.headline)
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
            .padding(.top, 10)

            if filteredAppointments.isEmpty {
                Text("No \(filter.rawValue.lowercased()) appointments.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                List(filteredAppointments) { appointment in
                    Button {
                        selectedAppointment = appointment
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Follow Up With \(appointment.prospect?.fullName ?? "Unknown")")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(appointment.prospect?.address ?? "No Address")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text(appointment.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showingProspectPicker) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schedule Follow Up")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                    Text("Choose a prospect to schedule your follow-up appointment")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 10)
                }
                .padding(.horizontal)
                .padding(.top)

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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1.0)
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color.white.ignoresSafeArea())
        }
        .sheet(item: $selectedProspect) { prospect in
            ScheduleAppointmentView(prospect: prospect)
        }
        .sheet(item: $selectedAppointment) { appt in
            AppointmentDetailsView(appointment: appt)
        }
    }
}
