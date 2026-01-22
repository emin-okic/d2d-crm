//
//  CreateEmailTemplateSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/21/26.
//

import SwiftUI


struct CreateEmailTemplateSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var subject = ""
    @State private var emailBody = ""

    var onSave: ((EmailTemplate) -> Void)? // <-- new

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Follow-up after visit", text: $title)
                }
                Section("Subject") {
                    TextField("Quick follow-up", text: $subject)
                }
                Section("Body") {
                    TextEditor(text: $emailBody)
                        .frame(minHeight: 120)
                    Text("Use {{name}} to insert the prospect’s name.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Email Template")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let template = EmailTemplate(
                            title: title,
                            subject: subject,
                            body: emailBody
                        )
                        modelContext.insert(template)
                        try? modelContext.save()
                        
                        // Call the callback
                        onSave?(template)
                        
                        dismiss()
                    }
                    .disabled(title.isEmpty || subject.isEmpty || emailBody.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
