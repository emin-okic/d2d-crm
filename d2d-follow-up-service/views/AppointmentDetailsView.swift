//
//  CancelAppointmentView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//
import SwiftUI
import SwiftData
import EventKit

struct AppointmentDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let appointment: Appointment

    // State for reschedule and cancel prompts
    @State private var showRescheduleSheet = false
    @State private var showRescheduleConfirmation = false
    @State private var showCancelConfirmation = false
    @State private var newDate: Date = Date()
    
    // Set state variables for setting appt
    @State private var calendarPermissionGranted = false
    @State private var calendarError: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // MARK: Header
                VStack(spacing: 8) {
                    Text("Follow-Up Appointment")
                        .font(.headline)
                    Text(appointment.date.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // MARK: Actions (icon buttons with confirmation)
                HStack(spacing: 32) {
                    Button {
                        showRescheduleConfirmation = true
                    } label: {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.title2)
                    }
                    .alert("Reschedule Appointment", isPresented: $showRescheduleConfirmation) {
                        Button("Continue") {
                            newDate = appointment.date
                            showRescheduleSheet = true
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Pick a new date and time for this appointment.")
                    }

                    Button {
                        showCancelConfirmation = true
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .alert("Cancel Appointment", isPresented: $showCancelConfirmation) {
                        Button("Yes", role: .destructive) {
                            context.delete(appointment)
                            try? context.save()
                            dismiss()
                        }
                        Button("No", role: .cancel) { }
                    } message: {
                        Text("This will permanently delete this appointment. Are you sure?")
                    }
                    
                    // Set an action for adding to ical
                    Button {
                        addAppointmentToCalendar(appointment)
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                    }
                    
                    // Create logic to check for existing events
                    if let error = calendarError {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    
                }
                .padding(.bottom)

                // MARK: Who & Where
                VStack(alignment: .leading, spacing: 6) {
                    Label(appointment.clientName, systemImage: "person.crop.circle")
                        .font(.title3)
                    Label(appointment.location, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: Notes
                if !appointment.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.title)
                        ForEach(appointment.notes, id: \.self) { note in
                            Text("• \(note)")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

            }
            .padding()
            .navigationTitle("Appointment Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // Sheet for actually picking new date
            .sheet(isPresented: $showRescheduleSheet) {
                RescheduleAppointmentView(
                    original: appointment,
                    newDate: $newDate
                ) {
                    context.delete(appointment)
                    let recreated = Appointment(
                        title: appointment.title,
                        location: appointment.location,
                        clientName: appointment.clientName,
                        date: newDate,
                        type: appointment.type,
                        notes: appointment.notes,
                        prospect: appointment.prospect!
                    )
                    context.insert(recreated)
                    try? context.save()
                    showRescheduleSheet = false
                    dismiss()
                }
            }
        }
    }
    
    private func addAppointmentToCalendar(_ appointment: Appointment) {
        let store = EKEventStore()

        store.requestAccess(to: .event) { granted, error in
            if let error = error {
                calendarError = "Calendar access error: \(error.localizedDescription)"
                return
            }

            if granted {
                calendarPermissionGranted = true

                let predicate = store.predicateForEvents(withStart: appointment.date.addingTimeInterval(-60),
                                                         end: appointment.date.addingTimeInterval(60),
                                                         calendars: nil)

                let existing = store.events(matching: predicate).first {
                    $0.title == appointment.title &&
                    $0.location == appointment.location
                }

                if existing != nil {
                    calendarError = "This event is already in your calendar."
                    return
                }

                let event = EKEvent(eventStore: store)
                event.title = appointment.title
                event.startDate = appointment.date
                event.endDate = appointment.date.addingTimeInterval(60 * 30) // 30 mins
                event.notes = appointment.notes.joined(separator: "\n")
                event.location = appointment.location
                event.calendar = store.defaultCalendarForNewEvents

                do {
                    try store.save(event, span: .thisEvent)
                    calendarError = "Event added to calendar!"
                } catch {
                    calendarError = "Failed to add event: \(error.localizedDescription)"
                }
            } else {
                calendarError = "Calendar access denied. Enable it in Settings."
            }
        }
    }
}
