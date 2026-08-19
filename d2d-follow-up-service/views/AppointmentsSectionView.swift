//
//  AppointmentsSectionView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//

import SwiftUI
import SwiftData

struct AppointmentsSectionView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var appointments: [Appointment]
    @Query private var prospects: [Prospect]

    @Binding var isEditing: Bool
    @Binding var selectedAppointments: Set<Appointment>
    @Binding var filteredAppointments: [Appointment]

    @State private var selectedAppointment: Appointment?
    @State private var appointmentToDelete: Appointment?
    @State private var showDeleteConfirmation = false
    @State private var selectedDate = Date()
    @State private var showMonthSwitcher = false

    private var calendar: Calendar { Calendar.current }

    private var selectedDayAppointments: [Appointment] {
        appointments
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date < $1.date }
    }

    private var visibleWeekDates: [Date] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start else {
            return [selectedDate]
        }

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStart)
        }
    }

    private var monthTitle: String {
        selectedDate.formatted(.dateTime.month(.wide).year())
    }

    private var selectedDayTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today's Appointments"
        }

        return selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            calendarHeader
            appointmentsContent
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.bottom, 12)
        .sheet(item: $selectedAppointment) { appt in
            AppointmentDetailsView(appointment: appt)
        }
        .alert("Delete Appointment?", isPresented: $showDeleteConfirmation, presenting: appointmentToDelete) { appt in
            Button("Delete", role: .destructive) {
                FollowUpScreenHapticsController.shared.mediumTap()
                FollowUpScreenSoundController.shared.playSound1()
                deleteAppointment(appt)
            }
            Button("Cancel", role: .cancel) {
                FollowUpScreenHapticsController.shared.lightTap()
                FollowUpScreenSoundController.shared.playSound1()
            }
        } message: { _ in
            Text("Are you sure you want to delete this appointment? This action cannot be undone.")
        }
        .onAppear(perform: syncFilteredAppointments)
        .onChange(of: selectedDate) {
            selectedAppointments.removeAll()
            isEditing = false
            syncFilteredAppointments()
        }
        .onChange(of: appointments) { _, _ in
            syncFilteredAppointments()
        }
    }

    private var calendarHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Button {
                        FollowUpScreenHapticsController.shared.lightTap()
                        FollowUpScreenSoundController.shared.playSound1()
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showMonthSwitcher.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(monthTitle)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.primary)

                            Image(systemName: showMonthSwitcher ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Text("\(selectedDayAppointments.count) \(appointmentLabel) on \(selectedDayTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 8)

                if !calendar.isDateInToday(selectedDate) {
                    Button {
                        moveToToday()
                    } label: {
                        Label("Today", systemImage: "calendar")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }

            if showMonthSwitcher {
                monthSwitcher
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: 8) {
                weekButton(systemImage: "chevron.left") {
                    moveWeek(by: -1)
                }

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(visibleWeekDates, id: \.self) { date in
                                dayButton(for: date)
                                    .id(calendar.startOfDay(for: date))
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                    .onAppear {
                        proxy.scrollTo(calendar.startOfDay(for: selectedDate), anchor: .center)
                    }
                    .onChange(of: selectedDate) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            proxy.scrollTo(calendar.startOfDay(for: selectedDate), anchor: .center)
                        }
                    }
                }

                weekButton(systemImage: "chevron.right") {
                    moveWeek(by: 1)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.18), value: selectedDate)
    }

    private var monthSwitcher: some View {
        HStack(spacing: 10) {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.bordered)

            VStack(spacing: 2) {
                Text(selectedDate.formatted(.dateTime.month(.wide)))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(selectedDate.formatted(.dateTime.year()))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator).opacity(0.24), lineWidth: 1)
                )
        )
    }

    private var appointmentsContent: some View {
        Group {
            if selectedDayAppointments.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(selectedDayAppointments) { appt in
                        AppointmentRowView(
                            appt: appt,
                            isEditing: isEditing,
                            isSelected: selectedAppointments.contains(appt)
                        )
                        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            handleTap(on: appt)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                FollowUpScreenHapticsController.shared.mediumTap()
                                FollowUpScreenSoundController.shared.playSound1()
                                appointmentToDelete = appt
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.secondary)

            Text("No appointments")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("There are no appointments scheduled for \(selectedDate.formatted(.dateTime.month(.abbreviated).day().year())).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 28)
    }

    private var appointmentLabel: String {
        selectedDayAppointments.count == 1 ? "appointment" : "appointments"
    }

    private func dayButton(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasAppointments = appointments.contains { calendar.isDate($0.date, inSameDayAs: date) }

        return Button {
            FollowUpScreenHapticsController.shared.lightTap()
            FollowUpScreenSoundController.shared.playSound1()
            selectedDate = date
        } label: {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isSelected ? .white.opacity(0.84) : .secondary)

                Text("\(calendar.component(.day, from: date))")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Circle()
                    .fill(hasAppointments ? (isSelected ? Color.white : Color.blue) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(width: 48, height: 62)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue.opacity(0.9) : Color(.separator).opacity(0.24), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
    }

    private func weekButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            FollowUpScreenHapticsController.shared.lightTap()
            FollowUpScreenSoundController.shared.playSound1()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 34, height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator).opacity(0.24), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func moveWeek(by value: Int) {
        if let newDate = calendar.date(byAdding: .weekOfYear, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func moveMonth(by value: Int) {
        FollowUpScreenHapticsController.shared.lightTap()
        FollowUpScreenSoundController.shared.playSound1()

        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func moveToToday() {
        FollowUpScreenHapticsController.shared.lightTap()
        FollowUpScreenSoundController.shared.playSound1()
        selectedDate = Date()
    }

    private func handleTap(on appt: Appointment) {
        FollowUpScreenHapticsController.shared.lightTap()
        FollowUpScreenSoundController.shared.playSound1()

        if isEditing {
            toggleSelection(for: appt)
        } else {
            selectedAppointment = appt
        }
    }

    private func toggleSelection(for appt: Appointment) {
        if selectedAppointments.contains(appt) {
            selectedAppointments.remove(appt)
        } else {
            selectedAppointments.insert(appt)
        }
    }

    private func deleteAppointment(_ appt: Appointment) {
        withAnimation {
            selectedAppointments.remove(appt)
            modelContext.delete(appt)

            do {
                try modelContext.save()
            } catch {
                print("Error saving after appointment deletion: \(error)")
            }
        }
    }

    private func syncFilteredAppointments() {
        filteredAppointments = selectedDayAppointments
    }

}
