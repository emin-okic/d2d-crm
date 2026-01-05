//
//  EditNoteSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import SwiftUI
import SwiftData
import UIKit

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
