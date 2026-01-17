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
        let store = EKEventStore()

        store.requestAccess(to: .event) { granted, error in
            if let error = error {
                showFeedback("Calendar access error: \(error.localizedDescription)")
                return
            }

            if granted {
                let predicate = store.predicateForEvents(
                    withStart: appointment.date.addingTimeInterval(-60),
                    end: appointment.date.addingTimeInterval(60),
                    calendars: nil
                )

                let existing = store.events(matching: predicate).first {
                    $0.title == appointment.title && $0.location == appointment.location
                }

                if existing != nil {
                    showFeedback("Already exists in calendar.")
                    return
                }

                let event = EKEvent(eventStore: store)
                event.title = appointment.title
                event.startDate = appointment.date
                event.endDate = appointment.date.addingTimeInterval(60 * 30)
                event.notes = appointment.notes.joined(separator: "\n")
                event.location = appointment.location
                event.calendar = store.defaultCalendarForNewEvents

                do {
                    try store.save(event, span: .thisEvent)
                    showFeedback("Successfully added to calendar!")
                } catch {
                    showFeedback("Failed to save event: \(error.localizedDescription)")
                }
            } else {
                showFeedback("Calendar access denied. Enable in Settings.")
            }
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
