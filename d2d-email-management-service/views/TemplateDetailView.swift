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
    
    let template: EmailTemplate
    let emailContext: EmailContactContext

    @State private var title: String
    @State private var subject: String
    @State private var emailBody: String

    @State private var originalTitle: String
    @State private var originalSubject: String
    @State private var originalBody: String

    @State private var showDeleteConfirmation = false

    init(template: EmailTemplate, emailContext: EmailContactContext) {
        self.template = template
        self.emailContext = emailContext

        let personalizedBody = template.body
            .replacingOccurrences(of: "{{name}}", with: emailContext.displayName)

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
    
    private let haptics = EmailManagerHapticsController.shared
    private let sounds = EmailManagerSoundController.shared

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
                            
                            haptics.lightTap()
                            sounds.playSound1()
                            
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
                                    
                                    haptics.lightTap()
                                    sounds.playSound1()
                                    
                                    title = originalTitle
                                    subject = originalSubject
                                    emailBody = originalBody
                                } label: {
                                    Image(systemName: "arrow.uturn.left")
                                        .foregroundColor(.red)
                                        .imageScale(.large)
                                }

                                Button("Save") {
                                    
                                    haptics.lightTap()
                                    sounds.playSound1()
                                    
                                    saveTemplateChanges()
                                }
                                .bold()
                            }
                        } else {
                            Button("Send") {
                                
                                haptics.lightTap()
                                sounds.playSound1()
                                
                                sendEmail()
                            }
                            .disabled(emailContext.getEmail().isEmpty)
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
                        
                        haptics.lightTap()
                        sounds.playSound1()
                        
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
                
                haptics.lightTap()
                sounds.playSound1()
                
                modelContext.delete(template)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                
                haptics.lightTap()
                sounds.playSound1()
                
            }
        } message: {
            Text("This template will be permanently deleted.")
        }
    }

    private func sendEmail() {
        let manager = EmailManager(
            context: emailContext,
            modelContext: modelContext
        )

        manager.send(template: template)
        dismiss()
    }

    private func saveTemplateChanges() {
        template.title = title
        template.subject = subject

        template.body = emailBody.replacingOccurrences(
            of: emailContext.displayName,
            with: "{{name}}"
        )

        try? modelContext.save()

        originalTitle = template.title
        originalSubject = template.subject
        originalBody = emailBody
    }
}
