//
//  AddNoteView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/11/25.
//


// Views/AddNoteView.swift
import SwiftUI
import SwiftData

struct LogNoteView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let prospect: Prospect
    let objection: Objection?
    let pendingAddress: String?
    let onComplete: () -> Void

    @State private var noteText: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Details")) {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                }

                Section {
                    Button("Save Note") {
                        var fullNote = ""

                        if let obj = objection {
                            fullNote = "Not Enough Interest: \(obj.text)\n\n\(noteText)"
                            obj.timesHeard += 1
                        } else if let addr = pendingAddress,
                                  prospect.knockHistory.last?.status == "Not Answered" {
                            fullNote = "No Answer\n\n\(noteText)"
                        } else {
                            fullNote = noteText
                        }

                        prospect.notes.append(Note(content: fullNote))
                        try? context.save()

                        noteText = ""
                        dismiss()
                        onComplete()
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
