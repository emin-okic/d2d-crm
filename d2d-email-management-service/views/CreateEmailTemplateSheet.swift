//
//  CreateEmailTemplateSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/21/26.
//

import SwiftUI
import SwiftData

struct CreateEmailTemplateSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var subject = ""
    @State private var emailBody = ""

    var onSave: ((EmailTemplate) -> Void)?
    
    private let haptics = EmailManagerHapticsController.shared
    private let sounds = EmailManagerSoundController.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.headline)
                        TextField("Follow-up after visit", text: $title)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    // Subject
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Subject")
                            .font(.headline)
                        TextField("Quick follow-up", text: $subject)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    // Email Body
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Body")
                            .font(.headline)
                        TextEditor(text: $emailBody)
                            .frame(minHeight: 180)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        
                        Text("Use {{name}} to insert the prospect’s name.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("New Email Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Left: Chevron Cancel
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        
                        haptics.lightTap()
                        sounds.playSound1()
                        
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }

                // Right: Save Button
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        
                        haptics.lightTap()
                        sounds.playSound1()
                        
                        let template = EmailTemplate(
                            title: title,
                            subject: subject,
                            body: emailBody
                        )
                        modelContext.insert(template)
                        try? modelContext.save()
                        
                        onSave?(template)
                        dismiss()
                    }
                    .bold()
                    .disabled(title.isEmpty || subject.isEmpty || emailBody.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
