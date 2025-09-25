//
//  CustomerNotesThreadSection.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/25/25.
//

import SwiftUI
import SwiftData
import UIKit

struct CustomerNotesThreadSection: View {
    @Bindable var customer: Customer
    @Environment(\.modelContext) private var context

    var maxHeight: CGFloat = 220
    var maxVisibleNotes: Int = 5
    var showChips: Bool = false

    @State private var draft: String = ""
    @State private var editingNote: Note? = nil
    @State private var showNotesSheet = false

    private var sortedNotes: [Note] {
        customer.notes.sorted { $0.date > $1.date }
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
                    Button("View all") { showNotesSheet = true }
                        .font(.caption)
                }
            }

            // Thread
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
                            Button(role: .destructive) { delete(note) } label: { Text("Delete") }
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

            // Composer
            NoteComposerBarCompact(
                text: $draft,
                placeholder: "Add a quick note…",
                onSubmit: { submitNote() },
                quickChips: showChips ? quickChips() : []
            )
        }
        .sheet(isPresented: $showNotesSheet) {
            CustomerNotesThreadFullView(customer: customer)
        }
        .sheet(item: $editingNote) { note in
            EditNoteSheet(note: note) { try? context.save() }
        }
    }

    private func submitNote() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = Note(content: trimmed, customer: customer)
        customer.notes.append(note)
        draft = ""
        try? context.save()
    }

    private func delete(_ note: Note) {
        if let idx = customer.notes.firstIndex(where: { $0 === note }) {
            customer.notes.remove(at: idx)
        }
        try? context.save()
    }

    private func quickChips() -> [NoteChip] {
        [
            .init(icon: "clock", label: "Door hanger", text: "Left door hanger. Will retry next pass."),
            .init(icon: "bolt.horizontal.circle", label: "Busy", text: "\(customer.fullName.isEmpty ? "Customer" : customer.fullName) was busy; try later."),
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
