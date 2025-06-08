//
//  AddNoteView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/8/25.
//


// AddNoteView.swift
import SwiftUI
import SwiftData

struct AddNoteView: View {
    @Bindable var prospect: Prospect

    @State private var newNoteText = ""
    @Environment(\.modelContext) private var context
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: "note.text")
                    .font(.title3)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 8) {
                    Text("New Note")
                        .font(.headline)

                    TextEditor(text: $newNoteText)
                        .focused($isFocused)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                }
            }

            HStack {
                Spacer()
                Button {
                    let note = Note(content: newNoteText, authorEmail: prospect.userEmail)
                    prospect.notes.append(note)
                    newNoteText = ""
                    isFocused = false
                    try? context.save()
                } label: {
                    Label("Post Note", systemImage: "paperplane.fill")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .animation(.easeInOut, value: newNoteText)
        .padding(.vertical, 8)
    }
}
