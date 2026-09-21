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
    @State private var selectedEmail: Email?
    @State private var selectedSection: EmailSheetSection = .templates
    @State private var selectedDetent: PresentationDetent = .fraction(0.72)

    @State private var emailError: String?
    @State private var showCreateTemplate = false
    @State private var showRevertConfirmation = false
    @State private var showMissingEmailAlert = false

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
            .sheet(item: $selectedEmail) { email in
                SentEmailPreviewSheet(email: email, context: context)
            }
            .alert("Revert Changes?", isPresented: $showRevertConfirmation) {
                Button("Revert", role: .destructive) {
                    tempEmail = context.getEmail()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will discard unsaved changes.")
            }
            .alert("Email Address Required", isPresented: $showMissingEmailAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enter and save an email address for this contact before sending an email.")
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
        LazyVStack(spacing: 10) {
            if sentEmails.isEmpty {
                emptyHistoryView
            } else {
                ForEach(sentEmails) { email in
                    Button {
                        selectedEmail = email
                    } label: {
                        historyRow(email)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        email.subject.isEmpty
                        ? "Sent email without a subject"
                        : email.subject
                    )
                    .accessibilityValue(
                        email.sentAt.formatted(date: .abbreviated, time: .shortened)
                    )
                    .accessibilityHint("Shows the sent email")
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
        HStack(spacing: 12) {
            Image(systemName: "paperplane.fill")
                .font(.subheadline)
                .foregroundStyle(.purple)
                .frame(width: 36, height: 36)
                .background(Color.purple.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(email.subject.isEmpty ? "No subject" : context.render(email.subject))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(email.sentAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 68)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .contentShape(Rectangle())
    }

    private func sendBlankEmail() {
        guard !context.getEmail().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showMissingEmailAlert = true
            return
        }

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

private struct SentEmailPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let email: Email
    let context: EmailContactContext

    private var subject: String {
        let renderedSubject = context.render(email.subject)
        return renderedSubject.isEmpty ? "No subject" : renderedSubject
    }

    private var bodyText: String {
        let renderedBody = context.render(email.body)
        return renderedBody.isEmpty ? "This email did not include a message." : renderedBody
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        emailField(label: "To", value: context.getEmail())
                        emailField(
                            label: "Sent",
                            value: email.sentAt.formatted(date: .long, time: .shortened)
                        )
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(subject)
                            .font(.headline)
                            .textSelection(.enabled)
                    }

                    Divider()

                    Text(bodyText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("Sent Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func emailField(label: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }
}
