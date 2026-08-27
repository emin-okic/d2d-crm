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

    private enum EmailSheetSection: String, CaseIterable, Identifiable {
        case templates = "Templates"
        case history = "History"

        var id: Self { self }
    }

    @State private var tempEmail: String = ""
    @State private var selectedTemplate: EmailTemplate?
    @State private var selectedSection: EmailSheetSection = .templates
    @State private var selectedDetent: PresentationDetent = .fraction(0.72)

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
        sentEmails.count
    }

    private var sentEmails: [Email] {
        emails
            .filter {
                $0.recipientUUID == context.id &&
                $0.recipientType == context.recipientType
            }
            .sorted { $0.sentAt > $1.sentAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {

                // Header
                VStack(spacing: 2) {
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .onChange(of: tempEmail) { validateEmail() }

                if let emailError {
                    Text(emailError)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Picker("Email Section", selection: $selectedSection) {
                    ForEach(EmailSheetSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)

                Group {
                    switch selectedSection {
                    case .templates:
                        templateTab
                    case .history:
                        historyTab
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .presentationDetents([.fraction(0.72), .large], selection: $selectedDetent)
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

    private var templateTab: some View {
        VStack(spacing: 10) {
            ScrollView(showsIndicators: false) {
                templateList
            }

            createTemplateButton
        }
        .frame(maxHeight: .infinity)
    }

    private var templateList: some View {
        VStack(spacing: 6) {

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
        }
    }

    private var createTemplateButton: some View {
        Button {
            haptics.lightTap()
            sounds.playSound1()
            showCreateTemplate = true
        } label: {
            Label("Create New Template", systemImage: "plus")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
    }

    private var historyTab: some View {
        ScrollView(showsIndicators: false) {
            emailHistoryList
        }
        .frame(maxHeight: .infinity)
    }

    private var emailHistoryList: some View {
        VStack(spacing: 6) {
            if sentEmails.isEmpty {
                emptyHistoryView
            } else {
                ForEach(sentEmails) { email in
                    historyRow(email)
                }
            }
        }
    }

    private var emptyHistoryView: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No emails sent yet")
                .font(.subheadline)
                .fontWeight(.medium)

            Text("Sent emails will appear here after you choose a template or start a blank email.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private func templateRow(title: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 56)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private func historyRow(_ email: Email) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(email.subject.isEmpty ? "Blank email" : email.subject)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(email.sentAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(email.templateUUID == nil ? "No template" : "Template")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(8)
            }

            if !email.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(email.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 64)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private func sendBlankEmail() {
        let manager = EmailManager(context: context, modelContext: modelContext)
        
        manager.sendBlank()
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
