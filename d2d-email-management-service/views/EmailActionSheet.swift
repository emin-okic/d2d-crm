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

    @Query(sort: \EmailTemplate.createdAt)
    private var templates: [EmailTemplate]

    @State private var showCreateTemplate = false
    @State private var emailError: String?
    @State private var showRevertConfirmation = false
    @State private var showTemplateDetail = false

    // MARK: - Dirty check
    private var hasUnsavedChanges: Bool {
        tempEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        != (prospect.contactEmail ?? "")
    }
    
    private let haptics = EmailManagerHapticsController.shared
    private let sounds = EmailManagerSoundController.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // Header
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.purple)
                        .font(.title3)
                    Text("Edit Email")
                        .font(.headline)
                }

                // Email field
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

                // Template Picker
                if !templates.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {

                            Button {
                                handleTemplateSelection(template: nil)
                            } label: {
                                templateRow(
                                    title: "Email Without Template",
                                    subtitle: "Start from a blank email"
                                )
                            }

                            ForEach(templates) { template in
                                Button {
                                    handleTemplateSelection(template: template)
                                } label: {
                                    templateRow(
                                        title: template.title,
                                        subtitle: template.subject
                                    )
                                }
                            }

                            Button("Create New Template") {
                                showCreateTemplate = true
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .toolbar {
                
                // Left
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        
                        haptics.lightTap()
                        sounds.playSound1()
                        
                        dismiss()
                        
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }

                // Right (ONLY when dirty)
                if hasUnsavedChanges {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            
                            haptics.mediumTap()
                            sounds.playSound1()
                            
                            showRevertConfirmation = true
                            
                        } label: {
                            Image(systemName: "arrow.uturn.left")
                        }
                        .tint(.red)

                        Button("Save") {
                            
                            haptics.mediumTap()
                            sounds.playSound1()
                            
                            saveEmail()
                            
                        }
                        .bold()
                        .disabled(!isEmailValid())
                    }
                }
            }
            .sheet(isPresented: $showCreateTemplate) {
                CreateEmailTemplateSheet { newTemplate in
                    apply(template: newTemplate)
                }
                .environment(\.modelContext, modelContext)
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(
                    prospect: prospect,
                    template: template
                )
                .environment(\.modelContext, modelContext)
            }
            .alert(
                "Revert Changes?",
                isPresented: $showRevertConfirmation
            ) {
                Button("Revert", role: .destructive) {
                    tempEmail = prospect.contactEmail ?? ""
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will discard unsaved changes.")
            }
            .onAppear {
                tempEmail = prospect.contactEmail ?? ""
            }
        }
    }

    // MARK: - Helpers

    private func templateRow(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).fontWeight(.medium)
                Text(subtitle)
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

    private func handleTemplateSelection(template: EmailTemplate?) {
        if let template {
            selectedTemplate = template   // ← this alone triggers the sheet
        } else {
            sendEmail(subject: "", body: "")
            dismiss()
        }
    }

    private func sendEmail(subject: String, body: String) {
        EmailComposer.compose(
            to: tempEmail,
            subject: subject,
            body: body
        )
        logEmailNote()
    }

    private func apply(template: EmailTemplate) {
        selectedTemplate = template
        subject = template.subject
        emailBody = template.body.replacingOccurrences(
            of: "{{name}}",
            with: prospect.fullName
        )
        tempEmail = prospect.contactEmail ?? ""
    }

    private func logEmailNote() {
        let note = Note(
            content: "Composed email to \(tempEmail) on \(Date().formatted(date: .abbreviated, time: .shortened)).",
            date: Date(),
            prospect: prospect
        )
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

        if previous.lowercased() != prospect.contactEmail.lowercased() {
            let note = Note(
                content: "Updated email from \(previous) to \(prospect.contactEmail).",
                date: Date(),
                prospect: prospect
            )
            prospect.notes.append(note)
        }

        try? modelContext.save()
    }
}
