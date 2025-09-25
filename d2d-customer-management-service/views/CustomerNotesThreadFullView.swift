//
//  CustomerNotesThreadFullView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/25/25.
//

import SwiftUI
import SwiftData
import UIKit

struct CustomerNotesThreadFullView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var customer: Customer

    @State private var draft: String = ""
    @State private var editingNote: Note? = nil

    private var sortedNotes: [Note] {
        customer.notes.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(sortedNotes, id: \.self) { note in
                            NoteRowCardCompact(
                                authorInitials: "You",
                                content: note.content,
                                date: note.date,
                                accent: tagAccent(for: note.content)
                            )
                            .contextMenu {
                                Button("Copy") { UIPasteboard.general.string = note.content }
                                Button("Edit") { editingNote = note }
                                Button(role: .destructive) { delete(note) } label: {
                                    Text("Delete")
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) { delete(note) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { editingNote = note } label: {
                                    Label("Edit", systemImage: "pencil")
                                }.tint(.blue)
                            }
                        }

                        if sortedNotes.isEmpty {
                            Text("No notes yet.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 24)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                NoteComposerBarCompact(
                    text: $draft,
                    placeholder: "Write a note…",
                    onSubmit: { submitNote() }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            .navigationTitle("All Notes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
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

    private func tagAccent(for content: String) -> NoteAccent? {
        let lower = content.lowercased()
        if lower.contains("follow up") { return .init(text: "Follow-Up", systemImage: "calendar.badge.clock") }
        if lower.contains("no answer") { return .init(text: "No Answer", systemImage: "house.slash.fill") }
        if lower.contains("converted") { return .init(text: "Converted", systemImage: "checkmark.seal.fill") }
        return nil
    }
}
