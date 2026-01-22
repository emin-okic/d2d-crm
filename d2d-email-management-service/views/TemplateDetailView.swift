//
//  TemplateDetailView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/22/26.
//
import SwiftUI

struct TemplateDetailView: View {
    @Environment(\.dismiss) var dismiss
    var prospect: Prospect
    var template: EmailTemplate

    @State private var subject: String
    @State private var emailBody: String

    init(prospect: Prospect, template: EmailTemplate) {
        self.prospect = prospect
        self.template = template
        _subject = State(initialValue: template.subject)
        _emailBody = State(initialValue: template.body.replacingOccurrences(of: "{{name}}", with: prospect.fullName))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Preview Email")
                .font(.headline)

            // Subject Field
            TextField("Subject", text: $subject)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

            // Body Field
            TextEditor(text: $emailBody)
                .frame(minHeight: 180)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

            // Send Button
            Button("Send") {
                EmailComposer.compose(to: prospect.contactEmail, subject: subject, body: emailBody)

                // Log note
                let note = Note(
                    content: "Sent email to \(prospect.contactEmail) on \(Date().formatted(date: .abbreviated, time: .shortened)).",
                    date: Date(),
                    prospect: prospect
                )
                prospect.notes.append(note)
                try? prospect.modelContext?.save()

                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(prospect.contactEmail.isEmpty)
        }
        .padding()
    }
}
