//
//  FollowUpScheduleFormView.swift
//  d2d-studio
//
//  Created by Codex on 8/6/26.
//

import SwiftUI

struct FollowUpScheduleFormView: View {
    @Environment(\.dismiss) private var dismiss

    let contactKind: String
    let contactName: String
    let contactAddress: String
    let contactNotes: [Note]
    let initialDate: Date
    let onSchedule: (_ date: Date, _ type: String) -> Void

    @State private var date: Date
    @State private var type = "Follow-Up"
    @State private var suppressNextDateFeedback = false

    private let quickDateOptions: [(title: String, days: Int)] = [
        ("Tomorrow", 1),
        ("Next week", 7),
        ("30 days", 30)
    ]

    init(
        contactKind: String,
        contactName: String,
        contactAddress: String,
        contactNotes: [Note],
        initialDate: Date = Date(),
        onSchedule: @escaping (_ date: Date, _ type: String) -> Void
    ) {
        self.contactKind = contactKind
        self.contactName = contactName
        self.contactAddress = contactAddress
        self.contactNotes = contactNotes
        self.initialDate = initialDate
        self.onSchedule = onSchedule
        _date = State(initialValue: initialDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            grabber
            topBar
            Divider()
            contentDeck
            Divider()
            actionDock
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.height(420), .large])
        .presentationDragIndicator(.hidden)
        .presentationContentInteraction(.scrolls)
    }

    private var grabber: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.34))
            .frame(width: 38, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 8)
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("New Follow-Up")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Schedule the next touchpoint")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                FollowUpScreenHapticsController.shared.lightTap()
                FollowUpScreenSoundController.shared.playSound1()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel Follow-Up")
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    private var contentDeck: some View {
        ScrollView {
            VStack(spacing: 0) {
                contactPanel
                panelDivider
                schedulePanel
                notesPanel
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .scrollIndicators(.hidden)
    }

    private var contactPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: contactKind == "Customer" ? "person.fill.checkmark" : "person.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(contactKind == "Customer" ? .green : .blue)
                    .frame(width: 32, height: 32)
                    .background((contactKind == "Customer" ? Color.green : Color.blue).opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(contactName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(contactAddress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Text(contactKind)
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(contactKind == "Customer" ? .green : .blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background((contactKind == "Customer" ? Color.green : Color.blue).opacity(0.10), in: Capsule())
            }
        }
    }

    private var schedulePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Label(type, systemImage: "tag.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)

                Spacer(minLength: 0)

                Text(date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("Date and time")
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 8)

                DatePicker("Date and time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .onChange(of: date) { _, _ in
                        if suppressNextDateFeedback {
                            suppressNextDateFeedback = false
                            return
                        }

                        FollowUpScreenHapticsController.shared.lightTap()
                        FollowUpScreenSoundController.shared.playSound1()
                    }
            }

            HStack(spacing: 8) {
                ForEach(quickDateOptions, id: \.title) { option in
                    quickDateButton(option.title, days: option.days)
                }
            }
        }
    }

    @ViewBuilder
    private var notesPanel: some View {
        if contactNotes.isEmpty == false {
            panelDivider

            VStack(alignment: .leading, spacing: 10) {
                Label("Recent notes", systemImage: "text.bubble.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(contactNotes.prefix(2), id: \.id) { note in
                    Text(note.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var panelDivider: some View {
        Divider()
            .padding(.vertical, 14)
    }

    private var actionDock: some View {
        HStack(spacing: 10) {
            Button {
                FollowUpScreenHapticsController.shared.lightTap()
                FollowUpScreenSoundController.shared.playSound1()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 46, height: 50)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityLabel("Cancel Follow-Up")

            Button {
                FollowUpScreenHapticsController.shared.successConfirmationTap()
                FollowUpScreenSoundController.shared.playSound1()
                onSchedule(date, type)
                dismiss()
            } label: {
                Label("Schedule", systemImage: "checkmark")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(Color.blue, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(.regularMaterial)
    }

    private func quickDateButton(_ title: String, days: Int) -> some View {
        Button {
            FollowUpScreenHapticsController.shared.lightTap()
            FollowUpScreenSoundController.shared.playSound1()
            suppressNextDateFeedback = true
            setQuickDate(days: days)
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
        .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func setQuickDate(days: Int) {
        guard let target = Calendar.current.date(byAdding: .day, value: days, to: Date()) else { return }
        let time = Calendar.current.dateComponents([.hour, .minute], from: date)
        date = Calendar.current.date(
            bySettingHour: time.hour ?? 9,
            minute: time.minute ?? 0,
            second: 0,
            of: target
        ) ?? target
    }
}
