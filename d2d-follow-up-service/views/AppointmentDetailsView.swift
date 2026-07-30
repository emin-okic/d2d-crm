//
//  CancelAppointmentView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//
import SwiftUI
import SwiftData
@preconcurrency import EventKit

private struct AppointmentDetailsEventStore: @unchecked Sendable {
    let store: EKEventStore
}

struct AppointmentDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let appointment: Appointment

    // State for reschedule and cancel prompts
    @State private var showRescheduleSheet = false
    @State private var newDate: Date = Date()
    @State private var showSuccessBanner = false
    @State private var successMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: Header Card
                    card {
                        VStack(spacing: 8) {
                            Text("Follow-Up Appointment")
                                .font(.headline)
                            Text(appointment.date.formatted(date: .long, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: Actions Toolbar Card
                    AppointmentActionsToolbar(
                        appointment: appointment,
                        onDelete: {
                            dismiss()
                        },
                        onReschedule: {
                            newDate = appointment.date
                            showRescheduleSheet = true
                        }
                    )
                    .padding(.horizontal)

                    // MARK: Who & Where Card
                    card {
                        VStack(alignment: .leading, spacing: 6) {
                            labeledField("Client") {
                                Text(appointment.clientName)
                                    .font(.subheadline)
                            }
                            labeledField("Location") {
                                Text(appointment.location)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // MARK: Notes Card
                    if !appointment.notes.isEmpty {
                        card {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.headline)
                                ForEach(appointment.notes, id: \.self) { note in
                                    Text("• \(note)")
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Appointment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        FollowUpScreenHapticsController.shared.lightTap()
                        FollowUpScreenSoundController.shared.playSound1()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.headline)
                    }
                }
            }
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
                .presentationDetents([
                    .fraction(0.35),
                ])
                .presentationDragIndicator(.visible)
            }

            // ✅ Success Banner floating over everything
            if showSuccessBanner {
                VStack {
                    Spacer().frame(height: 60)
                    Text(successMessage)
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
                .zIndex(999)
            }
        }
    }
    
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
    }

    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            content()
        }
    }
    
    // Helper function for opening in maps
    private func openInAppleMaps(destination: String) {
        let encodedAddress = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?daddr=\(encodedAddress)&dirflg=d"

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func addAppointmentToCalendar(_ appointment: Appointment) {
        let eventStore = AppointmentDetailsEventStore(store: EKEventStore())
        let title = appointment.title
        let startDate = appointment.date
        let endDate = appointment.date.addingTimeInterval(60 * 30)
        let location = appointment.location
        let notes = appointment.notes.joined(separator: "\n")

        let showCalendarFeedback: @Sendable (String) -> Void = { message in
            Task { @MainActor in
                showFeedback(message)
            }
        }

        let handleAccess: @Sendable (Bool, Error?) -> Void = { granted, error in
            if let error = error {
                showCalendarFeedback("Calendar access error: \(error.localizedDescription)")
                return
            }

            if granted {
                let predicate = eventStore.store.predicateForEvents(
                    withStart: startDate.addingTimeInterval(-60),
                    end: startDate.addingTimeInterval(60),
                    calendars: nil
                )

                let existing = eventStore.store.events(matching: predicate).first {
                    $0.title == title && $0.location == location
                }

                if existing != nil {
                    showCalendarFeedback("Already exists in calendar.")
                    return
                }

                let event = EKEvent(eventStore: eventStore.store)
                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.notes = notes
                event.location = location
                event.calendar = eventStore.store.defaultCalendarForNewEvents

                do {
                    try eventStore.store.save(event, span: .thisEvent)
                    showCalendarFeedback("Successfully added to calendar!")
                } catch {
                    showCalendarFeedback("Failed to save event: \(error.localizedDescription)")
                }
            } else {
                showCalendarFeedback("Calendar access denied. Enable in Settings.")
            }
        }

        if #available(iOS 17.0, *) {
            eventStore.store.requestFullAccessToEvents(completion: handleAccess)
        } else {
            eventStore.store.requestAccess(to: .event, completion: handleAccess)
        }
    }

    private func showFeedback(_ message: String) {
        DispatchQueue.main.async {
            successMessage = message
            withAnimation {
                showSuccessBanner = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showSuccessBanner = false
                }
            }
        }
    }
    
}
