//
//  TemplateDetailView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/22/26.
//
import SwiftUI

struct TemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    var prospect: Prospect
    var template: EmailTemplate

    @State private var subject: String
    @State private var emailBody: String

    // Keep track of the original template values
    @State private var originalSubject: String
    @State private var originalBody: String

    init(prospect: Prospect, template: EmailTemplate) {
        self.prospect = prospect
        self.template = template
        
        let personalizedBody = template.body.replacingOccurrences(of: "{{name}}", with: prospect.fullName)
        _subject = State(initialValue: template.subject)
        _emailBody = State(initialValue: personalizedBody)
        
        originalSubject = template.subject
        originalBody = personalizedBody
    }

    // Track if template has been edited
    private var hasEdits: Bool {
        subject != originalSubject || emailBody != originalBody
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                TextField("Subject", text: $subject)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                TextEditor(text: $emailBody)
                    .frame(minHeight: 180)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                Spacer()
            }
            .padding()
            .navigationTitle("Email Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Left: Dismiss
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }

                // Right: Send OR Save/Revert
                ToolbarItem(placement: .navigationBarTrailing) {
                    if hasEdits {
                        HStack(spacing: 12) {
                            
                            // Revert button as a curving left arrow
                            Button {
                                subject = originalSubject
                                emailBody = originalBody
                            } label: {
                                Image(systemName: "arrow.uturn.left")
                                    .foregroundColor(.red)
                                    .imageScale(.large)
                            }

                            Button("Save") {
                                saveTemplateChanges()
                            }
                            .bold()
                        }
                    } else {
                        Button("Send") {
                            sendEmail()
                        }
                        .disabled(prospect.contactEmail.isEmpty)
                        .bold()
                    }
                }
            }
        }
    }

    private func sendEmail() {
        EmailComposer.compose(to: prospect.contactEmail, subject: subject, body: emailBody)

        let note = Note(
            content: "Sent email to \(prospect.contactEmail) on \(Date().formatted(date: .abbreviated, time: .shortened)).",
            date: Date(),
            prospect: prospect
        )
        prospect.notes.append(note)
        try? modelContext.save()

        dismiss()
    }

    private func saveTemplateChanges() {
        template.subject = subject
        template.body = emailBody.replacingOccurrences(of: prospect.fullName, with: "{{name}}")
        try? modelContext.save()

        // Update the originals so the toolbar switches back to "Send"
        // after saving
        originalSubject = template.subject
        originalBody = template.body.replacingOccurrences(of: "{{name}}", with: prospect.fullName)
    }
}
