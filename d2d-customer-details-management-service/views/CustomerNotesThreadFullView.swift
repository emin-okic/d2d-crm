//
//  CustomerNotesThreadFullView.swift
//  d2d-studio
//
//  Created by Emin Okic on 10/17/25.
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
                                accent: nil
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
                    onSubmit: { submitNote() },
                    quickChips: []
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            .navigationTitle("All Notes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        
                        // ✅ Haptic & Sound
                        ContactScreenHapticsController.shared.lightTap()
                        ContactScreenSoundController.shared.playSound1()
                        
                        dismiss()
                        
                    }
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
        
        let note = Note(content: trimmed)
        customer.notes.append(note)
        draft = ""
        
        try? context.save()
        
        // ✅ Haptic & Sound
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()
        
    }

    private func delete(_ note: Note) {
        if let idx = customer.notes.firstIndex(where: { $0 === note }) {
            customer.notes.remove(at: idx)
        }
        try? context.save()
    }
}
