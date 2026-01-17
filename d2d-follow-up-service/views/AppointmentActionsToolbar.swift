//
//  AppointmentActionsToolbar.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/31/25.
//

import SwiftUI
import SwiftData
import EventKit

struct AppointmentActionsToolbar: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let appointment: Appointment

    // State
    @State private var showRescheduleConfirm = false
    @State private var showCancelConfirm = false
    @State private var showAddToCalendarConfirm = false
    @State private var showOpenInMapsConfirm = false
    
    var onDelete: (() -> Void)? = nil

    var onReschedule: () -> Void
    
    @State private var showCalendarChoice = false
    @StateObject private var calendarHelper = CalendarHelper()

    var body: some View {
        HStack(spacing: 24) {

            actionButton(
                icon: "arrow.clockwise",
                title: "Reschedule",
                color: .blue
            ) {
                
                FollowUpScreenHapticsController.shared.lightTap()
                FollowUpScreenSoundController.shared.playSound1()
                
                showRescheduleConfirm = true
                
            }

            actionButton(
                icon: "calendar.badge.plus",
                title: "Calendar",
                color: .purple
            ) {
                
                FollowUpScreenHapticsController.shared.lightTap()
                FollowUpScreenSoundController.shared.playSound1()
                
                showAddToCalendarConfirm = true
            }

            actionButton(
                icon: "car.fill",
                title: "Directions",
                color: .orange
            ) {
                
                FollowUpScreenHapticsController.shared.lightTap()
                FollowUpScreenSoundController.shared.playSound1()
                
                showOpenInMapsConfirm = true
            }

            actionButton(
                icon: "trash.fill",
                title: "Cancel",
                color: .red
            ) {
                
                FollowUpScreenHapticsController.shared.lightTap()
                FollowUpScreenSoundController.shared.playSound1()
                
                showCancelConfirm = true
                
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .overlay(confirmationDialogs)
        .sheet(isPresented: $showAddToCalendarConfirm) {
            ExportToCalendarSheet(
                appointment: appointment,
                calendarHelper: calendarHelper
            )
            .presentationDetents([.fraction(0.40)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Confirmation dialogs
    private var confirmationDialogs: some View {
        EmptyView()
            .alert("Reschedule Appointment?",
                   isPresented: $showRescheduleConfirm) {
                Button("Continue") {
                    
                    FollowUpScreenHapticsController.shared.mediumTap()
                    FollowUpScreenSoundController.shared.playSound1()
                    
                    onReschedule()
                }
                Button("Cancel", role: .cancel) {
                    
                    FollowUpScreenHapticsController.shared.mediumTap()
                    FollowUpScreenSoundController.shared.playSound1()
                    
                }
            }

            .alert("Open in Apple Maps?",
                   isPresented: $showOpenInMapsConfirm) {
                Button("Open Maps") {
                    
                    FollowUpScreenHapticsController.shared.successConfirmationTap()
                    FollowUpScreenSoundController.shared.playSound1()
                    
                    openInMaps(destination: appointment.location)
                }
                Button("Cancel", role: .cancel) {
                    
                    FollowUpScreenHapticsController.shared.successConfirmationTap()
                    FollowUpScreenSoundController.shared.playSound1()
                    
                }
            }

            .alert("Cancel Appointment?",
                   isPresented: $showCancelConfirm) {
                Button("Delete", role: .destructive) {
                    
                    FollowUpScreenHapticsController.shared.successConfirmationTap()
                    FollowUpScreenSoundController.shared.playSound1()
                    
                    context.delete(appointment)
                    try? context.save()
                    dismiss()
                    onDelete?()
                }
                Button("Keep", role: .cancel) {
                    
                    FollowUpScreenHapticsController.shared.successConfirmationTap()
                    FollowUpScreenSoundController.shared.playSound1()
                    
                }
            } message: {
                Text("This will permanently delete this appointment.")
            }
    }

    // MARK: - Shared CRM-style action button
    @ViewBuilder
    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50) // slightly smaller icon container
                    
                    Image(systemName: icon)
                        .font(.title3) // slightly smaller icon
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.caption2) // smaller text
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6) // shrink to fit instead of wrapping
                    .frame(maxWidth: 60) // same as icon width
            }
            .padding(2)
        }
        .buttonStyle(.plain)
        .shadow(color: color.opacity(0.25), radius: 4, x: 0, y: 2)
    }

    // MARK: - Helpers
    private func openInMaps(destination: String) {
        let encoded = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?daddr=\(encoded)&dirflg=d"

        if let url = URL(string: urlString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func addToCalendar() {
        let store = EKEventStore()
        store.requestAccess(to: .event) { granted, _ in
            guard granted else { return }

            let event = EKEvent(eventStore: store)
            event.title = appointment.title
            event.startDate = appointment.date
            event.endDate = appointment.date.addingTimeInterval(60 * 30)
            event.location = appointment.location
            event.calendar = store.defaultCalendarForNewEvents

            try? store.save(event, span: .thisEvent)
        }
    }
}
