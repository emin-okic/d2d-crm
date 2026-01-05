//
//  NotesThreadSection.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/15/25.
//


/// Unused

import SwiftUI
import SwiftData
import UIKit

// MARK: - Section Wrapper (Compact)
struct NotesThreadSection: View {
    @Bindable var prospect: Prospect
    @Environment(\.modelContext) private var context

    var maxHeight: CGFloat = 220
    var maxVisibleNotes: Int = 5
    var showChips: Bool = false

    @State private var draft: String = ""
    @State private var editingNote: Note? = nil

    // NEW: sheet control
    @State private var showNotesSheet = false

    private var sortedNotes: [Note] {
        prospect.notes.sorted { $0.date > $1.date }
    }
    private var visibleNotes: [Note] {
        Array(sortedNotes.prefix(maxVisibleNotes))
    }

    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Label("Notes", systemImage: "text.bubble.fill").font(.headline)
                if !sortedNotes.isEmpty {
                    Text("\(sortedNotes.count)")
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }
                Spacer()
                if sortedNotes.count > maxVisibleNotes {
                    // NEW: open full-screen sheet
                    Button("View all") { showNotesSheet = true }
                        .font(.caption)
                }
            }

            // Thread (fixed height for compact view)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(visibleNotes, id: \.self) { note in
                        NoteRowCardCompact(
                            authorInitials: "You",
                            content: note.content,
                            date: note.date,
                            accent: tagAccent(for: note.content)
                        )
                        .contextMenu {
                            Button("Copy") { UIPasteboard.general.string = note.content }
                            Button("Edit") { editingNote = note }
                            Button(role: .destructive) {
                                delete(note)
                            } label: { Text("Delete") }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { delete(note) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button { editingNote = note } label: {
                                Label("Edit", systemImage: "pencil")
                            }.tint(.blue)
                        }
                    }

                    if sortedNotes.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "text.bubble").foregroundColor(.secondary)
                            Text("No notes yet. Add your first one below.")
                                .foregroundColor(.secondary).font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: maxHeight)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Composer (compact)
            NoteComposerBarCompact(
                text: $draft,
                placeholder: "Add a quick note…",
                onSubmit: { submitNote() },
                quickChips: showChips ? quickChips() : []
            )
        }
        .sheet(isPresented: $showNotesSheet) {
            // NEW: full notes view in a sheet
            NotesThreadFullView(prospect: prospect)
        }
        .sheet(item: $editingNote) { note in
            EditNoteSheet(note: note) { try? context.save() }
        }
    }

    private func submitNote() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = Note(content: trimmed, prospect: prospect)
        prospect.notes.append(note)
        draft = ""
        try? context.save()
    }

    private func delete(_ note: Note) {
        if let idx = prospect.notes.firstIndex(where: { $0 === note }) {
            prospect.notes.remove(at: idx)
        }
        try? context.save()
    }

    private func quickChips() -> [NoteChip] {
        [
            .init(icon: "clock", label: "Door hanger", text: "Left door hanger. Will retry next pass."),
            .init(icon: "bolt.horizontal.circle", label: "Busy", text: "\(prospect.fullName.isEmpty ? "Prospect" : prospect.fullName) was busy; try later."),
            .init(icon: "calendar.badge.clock", label: "Follow-up", text: "Follow-up set. Will confirm day before.")
        ]
    }

    private func tagAccent(for content: String) -> NoteAccent? {
        let lower = content.lowercased()
        if lower.contains("follow up") || lower.contains("follow-up") {
            return .init(text: "Follow-Up", systemImage: "calendar.badge.clock")
        }
        if lower.contains("wasn't home") || lower.contains("no answer") {
            return .init(text: "No Answer", systemImage: "house.slash.fill")
        }
        if lower.contains("converted") || lower.contains("sale") {
            return .init(text: "Converted", systemImage: "checkmark.seal.fill")
        }
        return nil
    }
}

// MARK: - Compact Note Row
struct NoteRowCardCompact: View {
    let authorInitials: String
    let content: String
    let date: Date
    let accent: NoteAccent?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Small avatar
            ZStack {
                Circle().fill(Color(.systemGray5)).frame(width: 24, height: 24)
                Text(initials(authorInitials)).font(.caption2).bold()
            }

            // Slim card
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("You").font(.footnote).fontWeight(.semibold)
                    Text("·").foregroundColor(.secondary)
                    Text(relative(date)).font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    if let accent {
                        TagPillCompact(systemImage: accent.systemImage, text: accent.text)
                    }
                }

                Text(attributed(content))
                    .font(.subheadline) // smaller
                    .foregroundStyle(.primary)
                    .lineLimit(3)       // ⬅️ keep rows tidy
                    .textSelection(.enabled)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private func initials(_ text: String) -> String {
        let parts = text.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)) }
        return String(text.prefix(2)).uppercased()
    }

    private func relative(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }

    private func attributed(_ string: String) -> AttributedString {
        var out = AttributedString(string)

        // keywords
        let highlights = ["follow up", "follow-up", "converted", "sale", "wasn't home", "no answer"]
        for key in highlights {
            var cursor = out.startIndex
            while let r = out[cursor...].range(of: key, options: .caseInsensitive) {
                out[r].font = .subheadline.bold()
                cursor = r.upperBound
            }
        }

        // simple tokens
        let tokens = ["am","pm","AM","PM","Mon","Tue","Wed","Thu","Fri","Sat","Sun",
                      "January","February","March","April","May","June","July","August",
                      "September","October","November","December"]
        for t in tokens {
            var cursor = out.startIndex
            while let r = out[cursor...].range(of: t, options: .caseInsensitive) {
                out[r].font = .subheadline.bold()
                cursor = r.upperBound
            }
        }

        return out
    }
}

// MARK: - Compact Pill
struct TagPillCompact: View {
    let systemImage: String
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption2)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

struct NoteAccent {
    let text: String
    let systemImage: String
}

// MARK: - Compact Composer
struct NoteComposerBarCompact: View {
    @Binding var text: String
    var placeholder: String
    var onSubmit: () -> Void
    var quickChips: [NoteChip] = []

    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 6) {
            if !quickChips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(quickChips) { chip in
                            Button {
                                if text.isEmpty { text = chip.text }
                                else { text += (text.hasSuffix(" ") ? "" : " ") + chip.text }
                            } label: {
                                Label(chip.label, systemImage: chip.icon)
                                    .font(.caption2)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }

            HStack(spacing: 6) {
                TextField(placeholder, text: $text, axis: .vertical)
                    .focused($focused)
                    .lineLimit(1...3) // compact
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )

                Button(action: onSubmit) {
                    Image(systemName: "paperplane.fill").imageScale(.medium).padding(8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

struct NoteChip: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let text: String
}
// MARK: - Edit Sheet
struct EditNoteSheet: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var note: Note
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $note.content)
                        .frame(minHeight: 160)
                }
            }
            .navigationTitle("Edit Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}
