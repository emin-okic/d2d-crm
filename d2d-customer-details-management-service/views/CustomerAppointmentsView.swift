//
//  CustomerAppointmentsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI
import SwiftData

@available(iOS 18.0, *)
struct CustomerAppointmentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var customer: Customer
    @StateObject private var controller = CustomerAppointmentsController()
    @State private var filter: AppointmentFilter = .upcoming
    @State private var isSelecting = false
    @State private var selectedAppointmentIDs: Set<UUID> = []
    @State private var showDeleteConfirmation = false

    private var filteredAppointments: [Appointment] {
        let now = Date()

        switch filter {
        case .upcoming:
            return customer.appointments
                .filter { $0.isUpcomingBucket(now: now) }
                .sorted { $0.date < $1.date }
        case .past:
            return customer.appointments
                .filter { $0.isPastBucket(now: now) }
                .sorted { $0.date > $1.date }
        default:
            return []
        }
    }

    private var selectedAppointments: [Appointment] {
        customer.appointments.filter { selectedAppointmentIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            filterControl
            appointmentsList
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            actionToolbar
        }
        .sheet(isPresented: $controller.showAppointmentSheet) {
            ScheduleCustomerAppointmentView(customer: customer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $controller.selectedAppointment) { appt in
            AppointmentDetailsView(appointment: appt)
        }
        .confirmationDialog(
            "Delete selected appointments?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(selectedAppointmentIDs.count) Appointment\(selectedAppointmentIDs.count == 1 ? "" : "s")", role: .destructive) {
                deleteSelectedAppointments()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the selected appointment\(selectedAppointmentIDs.count == 1 ? "" : "s") from \(customer.fullName).")
        }
        .onChange(of: filter) {
            selectedAppointmentIDs.removeAll()
            isSelecting = false
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Appointments")
                    .font(.title3.weight(.semibold))
                Text("\(filteredAppointments.count) \(filter.rawValue.lowercased()) for \(customer.fullName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            Button {
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                controller.showAppointmentSheet = true
            } label: {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Circle())
            .accessibilityLabel("Add appointment")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var filterControl: some View {
        Picker("Appointment filter", selection: $filter) {
            Text("Upcoming").tag(AppointmentFilter.upcoming)
            Text("Past").tag(AppointmentFilter.past)
        }
        .pickerStyle(.segmented)
    }

    private var appointmentsList: some View {
        Group {
            if filteredAppointments.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredAppointments) { appointment in
                            Button {
                                handleAppointmentTap(appointment)
                            } label: {
                                appointmentRow(appointment)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)
            Text("No \(filter.rawValue.lowercased()) appointments")
                .font(.headline)
            Text("New meetings for this customer will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var actionToolbar: some View {
        HStack(spacing: 10) {
            Button {
                ContactScreenHapticsController.shared.lightTap()
                ContactScreenSoundController.shared.playSound1()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSelecting.toggle()
                    selectedAppointmentIDs.removeAll()
                }
            } label: {
                Label(isSelecting ? "Done" : "Select", systemImage: isSelecting ? "checkmark" : "checklist")
            }
            .buttonStyle(.bordered)
            .disabled(filteredAppointments.isEmpty)

            if isSelecting {
                Button(role: .destructive) {
                    ContactScreenHapticsController.shared.lightTap()
                    ContactScreenSoundController.shared.playSound1()
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedAppointmentIDs.isEmpty)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private func appointmentRow(_ appointment: Appointment) -> some View {
        let isSelected = selectedAppointmentIDs.contains(appointment.id)

        return HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .red : .secondary)
                    .frame(width: 26, height: 26)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.title.isEmpty ? "Follow Up With \(customer.fullName)" : appointment.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Label(customer.address, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Label(appointment.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if !isSelecting {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .frame(minHeight: 82)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.red.opacity(0.08) : Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.red.opacity(0.45) : Color(.separator).opacity(0.35), lineWidth: 1)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private func handleAppointmentTap(_ appointment: Appointment) {
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()

        if isSelecting {
            if selectedAppointmentIDs.contains(appointment.id) {
                selectedAppointmentIDs.remove(appointment.id)
            } else {
                selectedAppointmentIDs.insert(appointment.id)
            }
        } else {
            controller.selectedAppointment = appointment
        }
    }

    private func deleteSelectedAppointments() {
        for appointment in selectedAppointments {
            modelContext.delete(appointment)
        }

        try? modelContext.save()

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedAppointmentIDs.removeAll()
            isSelecting = false
        }
    }
}
