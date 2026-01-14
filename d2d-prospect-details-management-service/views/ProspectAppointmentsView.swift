//
//  ProspectAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI
import SwiftData

struct ProspectAppointmentsView: View {

    @Bindable var prospect: Prospect
    @ObservedObject var controller: ProspectDetailsController
    @State private var filter: AppointmentFilter = .upcoming

    private var filteredAppointments: [Appointment] {
        let cal = Calendar.current
        let now = Date()

        switch filter {
        case .upcoming:
            return prospect.appointments
                .filter { $0.date >= cal.startOfDay(for: now) }
                .sorted { $0.date < $1.date }
        case .past:
            return prospect.appointments
                .filter { $0.date < cal.startOfDay(for: now) }
                .sorted { $0.date > $1.date }
        default:
            return []
        }
    }

    var body: some View {
        GeometryReader { geo in
            let topPad: CGFloat = geo.size.height < 500 ? 20 : 40
            let buttonSize: CGFloat = 48
            let buttonPadding: CGFloat = 12
            let buttonTotalHeight = buttonSize + (buttonPadding * 2)

            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 16) {

                    // Header
                    VStack(spacing: 4) {
                        Text("Appointments")
                            .font(.title2).bold()
                        Text("\(filteredAppointments.count) \(filter.rawValue) for \(prospect.fullName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2)
                    .padding(.horizontal, 12)
                    .padding(.top, topPad)

                    // Filters
                    HStack(spacing: 8) {
                        chip("Upcoming", isOn: filter == .upcoming) { filter = .upcoming }
                        chip("Past", isOn: filter == .past) { filter = .past }
                    }
                    .padding(.horizontal, 12)

                    // Container
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .shadow(color: .black.opacity(0.05), radius: 4)

                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if filteredAppointments.isEmpty {
                                    Text("No \(filter.rawValue) Appointments")
                                        .font(.title3.weight(.semibold))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 24)
                                } else {
                                    ForEach(filteredAppointments) { appt in
                                        Button {
                                            ContactDetailsHapticsController.shared.mapTap()
                                            ContactScreenSoundController.shared.playPropertyOpen()
                                            controller.selectedAppointmentDetails = appt
                                        } label: {
                                            appointmentRow(appt)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding()
                            .padding(.bottom, buttonTotalHeight)
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: geo.size.height - topPad - 150
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }

                // Floating Add Button
                Button {
                    ContactDetailsHapticsController.shared.mapTap()
                    ContactScreenSoundController.shared.playPropertyOpen()
                    controller.showAppointmentSheet = true
                } label: {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 12)
                .padding(.bottom, 12)
            }
        }
        .sheet(isPresented: $controller.showAppointmentSheet) {
            NavigationStack {
                ScheduleAppointmentView(prospect: prospect)
            }
        }
        .sheet(item: $controller.selectedAppointmentDetails) { appt in
            AppointmentDetailsView(appointment: appt)
        }
    }

    // MARK: - Chips
    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isOn ? Color.blue : Color(.secondarySystemBackground))
                )
                .foregroundColor(isOn ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOn ? Color.blue.opacity(0.9) : Color.gray.opacity(0.25))
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }

    // MARK: - Row
    private func appointmentRow(_ appt: Appointment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Follow Up With \(prospect.fullName)")
                    .font(.subheadline).fontWeight(.medium)
                Text(prospect.address)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4)
        )
    }
}
