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

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Add a note...", text: $newNoteText)
                .textFieldStyle(.roundedBorder)

            Button("Post Note") {
                let note = Note(content: newNoteText, authorEmail: prospect.userEmail)
                prospect.notes.append(note)
                newNoteText = ""
                try? context.save()
            }
            .disabled(newNoteText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.vertical, 4)
    }
}
