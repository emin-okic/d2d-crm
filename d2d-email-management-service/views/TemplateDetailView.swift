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

    @State private var title: String
    @State private var subject: String
    @State private var emailBody: String

    @State private var originalTitle: String
    @State private var originalSubject: String
    @State private var originalBody: String

    @State private var showDeleteConfirmation = false

    init(prospect: Prospect, template: EmailTemplate) {
        self.prospect = prospect
        self.template = template
        
        let personalizedBody = template.body.replacingOccurrences(of: "{{name}}", with: prospect.fullName)
        _title = State(initialValue: template.title)
        _subject = State(initialValue: template.subject)
        _emailBody = State(initialValue: personalizedBody)
        
        originalTitle = template.title
        originalSubject = template.subject
        originalBody = personalizedBody
    }

    private var hasEdits: Bool {
        title != originalTitle || subject != originalSubject || emailBody != originalBody
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Template Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Template Title")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("Enter a descriptive title", text: $title)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }

                        // Subject
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Subject")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("Enter email subject", text: $subject)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }

                        // Body
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Body")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $emailBody)
                                .frame(minHeight: 200)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            Text("Use {{name}} to insert the prospect’s name automatically.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }

                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Email Template")
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

                    // Right: Send or Save/Revert
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if hasEdits {
                            HStack(spacing: 12) {
                                // Revert button
                                Button {
                                    title = originalTitle
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

            // MARK: - Floating Trash Button (bottom-left)
            VStack {
                Spacer()
                HStack {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.red))
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 20)
                    .padding(.bottom, 30)

                    Spacer()
                }
            }
        }
        // MARK: - Delete Confirmation Alert
        .alert("Delete Template?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(template)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This template will be permanently deleted.")
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
        template.title = title
        template.subject = subject
        template.body = emailBody.replacingOccurrences(of: prospect.fullName, with: "{{name}}")
        try? modelContext.save()

        originalTitle = template.title
        originalSubject = template.subject
        originalBody = template.body.replacingOccurrences(of: "{{name}}", with: prospect.fullName)
    }
}
