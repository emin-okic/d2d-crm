//
//  AppointmentDetailsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/6/25.
//

import SwiftUI
import SwiftData

struct AppointmentDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var appointment: Appointment

    @State private var showRescheduleSheet = false
    @State private var newDate: Date = Date()
    @State private var isGeneratingSummary = false

    private var notesController: AppointmentNotesController {
        AppointmentNotesController(modelContext: context)
    }

    private var canReopenAppointment: Bool {
        appointment.canReopen()
    }

    private var isCompletionButtonDisabled: Bool {
        isGeneratingSummary || (appointment.isClosed && canReopenAppointment == false)
    }

    private var completionButtonTitle: String {
        if isGeneratingSummary {
            return "Summarizing Notes"
        }

        if canReopenAppointment {
            return "Reopen Meeting"
        }

        return appointment.isClosed ? "Meeting Done" : "Confirm Meeting Done"
    }

    private var completionButtonIcon: String {
        if isGeneratingSummary {
            return "sparkles"
        }

        if canReopenAppointment {
            return "arrow.uturn.backward"
        }

        return appointment.isClosed ? "checkmark.circle.fill" : "checkmark"
    }

    private var completionButtonColor: Color {
        if isCompletionButtonDisabled {
            return Color(.systemGray5)
        }

        return canReopenAppointment ? .orange : .blue
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isCompact = geo.size.height < 680

                VStack(spacing: isCompact ? 10 : 14) {
                    headerCard(isCompact: isCompact)

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
                    .padding(.horizontal, 4)

                    contactCard(isCompact: isCompact)

                    if appointment.notes.isEmpty == false && isCompact == false {
                        contextNotesCard
                    }

                    Spacer(minLength: 0)

                    notesCard

                    completionButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
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
                    appointment.date = newDate
                    try? context.save()
                    showRescheduleSheet = false
                    dismiss()
                }
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                Task {
                    await notesController.closePastAppointmentIfNeeded(appointment)
                }
            }
        }
    }

    private func headerCard(isCompact: Bool) -> some View {
        card {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: appointment.isClosed ? "checkmark.seal.fill" : "calendar")
                    .font(.system(size: isCompact ? 16 : 18, weight: .semibold))
                    .foregroundColor(appointment.isClosed ? .secondary : .blue)
                    .frame(width: 36, height: 36)
                    .background((appointment.isClosed ? Color.gray : Color.blue).opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.type)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(appointment.date.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 0)

                Text(appointment.isClosed ? "Done" : "Open")
                    .font(.caption.weight(.bold))
                    .foregroundColor(appointment.isClosed ? .secondary : .blue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background((appointment.isClosed ? Color.gray : Color.blue).opacity(0.10), in: Capsule())
            }
        }
    }

    private func contactCard(isCompact: Bool) -> some View {
        card {
            VStack(alignment: .leading, spacing: isCompact ? 8 : 10) {
                labeledField("Client") {
                    contactDetailsLink
                }

                labeledField("Location") {
                    Text(appointment.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    @ViewBuilder
    private var contactDetailsLink: some View {
        if let prospect = appointment.prospect {
            NavigationLink {
                ProspectDetailsView(prospect: prospect)
                    .navigationBarBackButtonHidden(true)
            } label: {
                contactLinkLabel(contactTypeTitle: "Prospect")
            }
            .simultaneousGesture(TapGesture().onEnded(playContactOpenFeedback))
            .buttonStyle(.plain)
        } else if let customer = appointment.customer {
            NavigationLink {
                CustomerDetailsView(customer: customer)
                    .navigationBarBackButtonHidden(true)
            } label: {
                contactLinkLabel(contactTypeTitle: "Customer")
            }
            .simultaneousGesture(TapGesture().onEnded(playContactOpenFeedback))
            .buttonStyle(.plain)
        } else {
            Text(appointment.clientName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private func contactLinkLabel(contactTypeTitle: String) -> some View {
        HStack(spacing: 10) {
            Text(appointment.clientName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(contactTypeTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1), in: Capsule())

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityLabel("Open \(contactTypeTitle) details for \(appointment.clientName)")
    }

    private var contextNotesCard: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                Label("Contact Context", systemImage: "text.bubble")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(appointment.notes.prefix(2), id: \.self) { note in
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var notesCard: some View {
        card {
            AppointmentMeetingNotesView(appointment: appointment) { note in
                notesController.addMeetingNote(note, to: appointment)
            }
        }
    }

    private var completionButton: some View {
        Button {
            FollowUpScreenHapticsController.shared.successConfirmationTap()
            FollowUpScreenSoundController.shared.playSound1()

            if canReopenAppointment {
                notesController.reopenIfAllowed(appointment)
            } else {
                isGeneratingSummary = true
                Task {
                    await notesController.completeIfNeeded(appointment)
                    isGeneratingSummary = false
                }
            }
        } label: {
            Label(completionButtonTitle, systemImage: completionButtonIcon)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(.plain)
        .foregroundColor(isCompletionButtonDisabled ? .secondary : .white)
        .background(completionButtonColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .disabled(isCompletionButtonDisabled)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
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

    private func playContactOpenFeedback() {
        FollowUpScreenHapticsController.shared.lightTap()
        FollowUpScreenSoundController.shared.playSound1()
    }
}
