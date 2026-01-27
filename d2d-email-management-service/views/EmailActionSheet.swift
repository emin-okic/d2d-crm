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

    let context: EmailContactContext

    @State private var tempEmail: String = ""
    @State private var selectedTemplate: EmailTemplate?

    @State private var emailError: String?
    @State private var showCreateTemplate = false
    @State private var showRevertConfirmation = false

    @Query(sort: \EmailTemplate.createdAt)
    private var templates: [EmailTemplate]

    private var hasUnsavedChanges: Bool {
        tempEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        != context.getEmail().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private let haptics = EmailManagerHapticsController.shared
    private let sounds = EmailManagerSoundController.shared
    
    @Query private var emails: [Email]

    private var emailCount: Int {
        emails.filter {
            $0.recipientUUID == context.id &&
            $0.recipientType == context.recipientType
        }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // Header
                VStack(spacing: 4) {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.purple)
                            .font(.title3)

                        Text("Email")
                            .font(.headline)
                    }

                    Text("\(emailCount) emails sent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Email Field
                TextField("name@example.com", text: $tempEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .onChange(of: tempEmail) { _ in validateEmail() }

                if let emailError {
                    Text(emailError)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // Templates
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {

                        Button {
                            sendBlankEmail()
                        } label: {
                            templateRow(
                                title: "Email Without Template",
                                subtitle: "Start from a blank email"
                            )
                        }

                        ForEach(templates) { template in
                            Button {
                                selectedTemplate = template
                            } label: {
                                templateRow(
                                    title: template.title,
                                    subtitle: template.subject
                                )
                            }
                        }

                        Button("Create New Template") {
                            haptics.lightTap()
                            sounds.playSound1()
                            showCreateTemplate = true
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .navigationTitle("")
            .toolbar {

                // Cancel (Chevron)
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

                // Save / Revert (only when dirty)
                if hasUnsavedChanges {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            showRevertConfirmation = true
                        } label: {
                            Image(systemName: "arrow.uturn.left")
                        }
                        .tint(.red)

                        Button("Save") {
                            saveEmail()
                        }
                        .bold()
                        .disabled(!isEmailValid())
                    }
                }
            }
            .sheet(isPresented: $showCreateTemplate) {
                CreateEmailTemplateSheet { newTemplate in
                    selectedTemplate = newTemplate
                }
                .environment(\.modelContext, modelContext)
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(
                    template: template,
                    emailContext: context
                )
                .environment(\.modelContext, modelContext)
            }
            .alert("Revert Changes?", isPresented: $showRevertConfirmation) {
                Button("Revert", role: .destructive) {
                    tempEmail = context.getEmail()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will discard unsaved changes.")
            }
            .onAppear {
                tempEmail = context.getEmail()
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

    private func sendBlankEmail() {
        let manager = EmailManager(context: context, modelContext: modelContext)
        manager.sendBlank()
        dismiss()
    }

    private func saveEmail() {
        let trimmed = tempEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let previous = context.getEmail()

        context.setEmail(trimmed)

        if previous.lowercased() != trimmed.lowercased() {
            let note = Note(
                content: "Updated email from \(previous) to \(trimmed).",
                date: Date()
            )
            context.appendNote(note)
        }

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
}
