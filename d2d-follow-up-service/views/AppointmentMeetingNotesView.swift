//
//  AppointmentMeetingNotesView.swift
//  d2d-studio
//
//  Created by Codex on 8/7/26.
//

import SwiftUI
import UIKit

struct AppointmentMeetingNotesView: View {
    let appointment: Appointment
    let onAddNote: (String) -> Void

    @State private var draftNote = ""

    private var canAddNote: Bool {
        draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && appointment.isClosed == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("Meeting Notes", systemImage: "note.text")
                    .font(.headline)
                Spacer(minLength: 0)
                if appointment.isClosed {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            notesList

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Add meeting note", text: $draftNote, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(2...4)
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .disabled(appointment.isClosed)

                Button {
                    onAddNote(draftNote)
                    draftNote = ""
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .foregroundStyle(canAddNote ? .white : .secondary)
                .background(canAddNote ? Color.blue : Color(.systemGray5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(canAddNote == false)
                .accessibilityLabel("Add Meeting Note")
            }
        }
    }

    @ViewBuilder
    private var notesList: some View {
        if appointment.meetingNotes.isEmpty {
            Text(appointment.isClosed ? "No meeting notes were captured." : "Capture sales notes before closing this meeting.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(appointment.meetingNotes.enumerated()), id: \.offset) { _, note in
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(Color.blue.opacity(0.55))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)

                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contextMenu {
                                Button("Copy") {
                                    UIPasteboard.general.string = note
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
        }
    }
}
