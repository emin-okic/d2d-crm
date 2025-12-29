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

    // Parent bindings for multi-delete
    @Binding var isEditing: Bool
    @Binding var selectedAppointments: Set<Appointment>

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
    
    private let rowHeight: CGFloat = 74
    var maxScrollHeight: CGFloat? = nil

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // Header
                    VStack(alignment: .center, spacing: 5) {
                        Text("Appointments")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(filter == .upcoming
                             ? "\(upcomingCount) Upcoming Appointments"
                             : "\(pastCount) Past Appointments")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    
                    // Toggle chips
                    HStack(spacing: 8) {
                        toggleChip("Upcoming", isOn: filter == .upcoming) { filter = .upcoming }
                        toggleChip("Past",     isOn: filter == .past)     { filter = .past }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)

                    // Empty / list
                    if filteredAppointments.isEmpty {
                        Text("No \(filter.rawValue) Appointments")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredAppointments) { appt in
                                    Button {
                                        if isEditing {
                                            toggleSelection(for: appt)
                                        } else {
                                            selectedAppointment = appt
                                        }
                                    } label: {
                                        AppointmentRowView(
                                            appt: appt,
                                            isEditing: isEditing,
                                            isSelected: selectedAppointments.contains(appt)
                                        )
                                    }
                                    Divider()
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                        .frame(maxHeight: maxScrollHeight ?? rowHeight * 3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, 12)
                .sheet(item: $selectedAppointment) { appt in
                    AppointmentDetailsView(appointment: appt)
                }
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
    }

    // MARK: - Multi-select helpers
    private func toggleSelection(for appt: Appointment) {
        if selectedAppointments.contains(appt) {
            selectedAppointments.remove(appt)
        } else {
            selectedAppointments.insert(appt)
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
