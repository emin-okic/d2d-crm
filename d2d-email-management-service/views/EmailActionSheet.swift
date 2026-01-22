//
//  EmailActionSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/22/26.
//


//
//  EmailActionSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/21/26.
//

import SwiftUI
import SwiftData

struct EmailActionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var prospect: Prospect
    
    @State private var tempEmail: String = ""
    @State private var subject: String = ""
    @State private var emailBody: String = ""

    @State private var selectedTemplate: EmailTemplate?

    @Query(sort: \EmailTemplate.createdAt) private var templates: [EmailTemplate]
    @State private var showCreateTemplate = false
    @State private var emailError: String?

    @State private var showRevertConfirmation = false

    // ✅ Computed property to check if there are unsaved changes
    private var hasUnsavedChanges: Bool {
        tempEmail.trimmingCharacters(in: .whitespacesAndNewlines) != (prospect.contactEmail ?? "")
    }

    var body: some View {
        VStack(spacing: 16) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Header
            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text("Edit Email")
                    .font(.headline)
            }

            // Email Input (always visible)
            TextField("name@example.com", text: $tempEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
                .onChange(of: tempEmail) { _ in validateEmail() }

            if let emailError = emailError {
                Text(emailError)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Show Save + Revert buttons whenever user edits the email
            if hasUnsavedChanges {
                HStack(spacing: 12) {
                    Button("Revert") {
                        showRevertConfirmation = true
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Button("Save") {
                        saveEmail()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .disabled(!isEmailValid() || tempEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            // Template Picker
            if !templates.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {

                        // ✅ Add this
                        Button {
                            tempEmail = prospect.contactEmail ?? ""
                            subject = ""
                            emailBody = ""
                            selectedTemplate = nil
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Email Without Template")
                                        .fontWeight(.medium)
                                    Text("Start from a blank email")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)

                        ForEach(templates) { template in
                            Button {
                                apply(template: template)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.title)
                                            .fontWeight(.medium)
                                        Text(template.subject)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }

                        Button("Create New Template") { showCreateTemplate = true }
                            .padding(.top, 4)
                    }
                }
            }

            Button("Send Email") {
                EmailComposer.compose(
                    to: tempEmail,
                    subject: subject,
                    body: emailBody
                )

                logEmailNote()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isEmailValid() || tempEmail.isEmpty)
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showCreateTemplate) {
            CreateEmailTemplateSheet(onSave: { newTemplate in
                showCreateTemplate = false
                apply(template: newTemplate)
            })
            .environment(\.modelContext, modelContext)
        }
        .alert(
            "Revert Changes?",
            isPresented: $showRevertConfirmation,
            actions: {
                Button("Revert", role: .destructive) {
                    tempEmail = prospect.contactEmail
                }
                Button("Cancel", role: .cancel) {}
            },
            message: {
                Text("This will discard unsaved changes.")
            }
        )
        .onAppear {
            // Always populate the email field with the prospect’s email
            tempEmail = prospect.contactEmail ?? ""
        }
    }

    private func apply(template: EmailTemplate) {
        selectedTemplate = template
        subject = template.subject
        emailBody = template.body.replacingOccurrences(
            of: "{{name}}",
            with: prospect.fullName
        )
        tempEmail = prospect.contactEmail ?? "" // keep tempEmail in sync
    }

    private func logEmailNote() {
        let content = "Composed email to \(tempEmail) on \(Date().formatted(date: .abbreviated, time: .shortened))."
        let note = Note(content: content, date: Date(), prospect: prospect)
        prospect.notes.append(note)
        try? modelContext.save()
    }

    private func isEmailValid() -> Bool {
        let raw = tempEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return raw.range(of: pattern, options: .regularExpression) != nil
    }

    private func validateEmail() {
        emailError = isEmailValid() ? nil : "Invalid email address."
    }

    private func saveEmail() {
        guard isEmailValid() else { return }

        let previous = prospect.contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        prospect.contactEmail = tempEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        // Log note if changed
        if previous.lowercased() != prospect.contactEmail.lowercased() {
            let noteContent: String
            if previous.isEmpty {
                noteContent = "Added email \(prospect.contactEmail)."
            } else {
                noteContent = "Updated email from \(previous) to \(prospect.contactEmail)."
            }
            let note = Note(content: noteContent, date: Date(), prospect: prospect)
            prospect.notes.append(note)
        }

        // Save to SwiftData
        try? modelContext.save()
    }
}
