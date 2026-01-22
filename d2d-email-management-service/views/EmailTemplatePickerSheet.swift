//
//  EmailTemplatePickerSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/21/26.
//

import SwiftUI
import SwiftData

struct EmailTemplatePickerSheet: View {
    @Query(sort: \EmailTemplate.createdAt)
    private var templates: [EmailTemplate]

    @State private var showCreateTemplate = false

    @StateObject var controller: EmailTemplatesController
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            Text("Email Templates")
                .font(.headline)

            if templates.isEmpty {
                emptyState
            } else {
                templateList
            }

            Spacer()
        }
        .padding()
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showCreateTemplate) {
            CreateEmailTemplateSheet(onSave: { newTemplate in
                showCreateTemplate = false
            })
            .environment(\.modelContext, controller.modelContext) // <-- important
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No templates yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Create Email Template") {
                showCreateTemplate = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 20)
    }

    private var templateList: some View {
        VStack(spacing: 8) {
            
            Button {
                controller.composeBlankEmail()
                onClose()
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Blank Email")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Existing templates
            ForEach(templates) { template in
                Button {
                    controller.compose(template: template)
                    onClose()
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

            // Option to continue without a template
            Button("Continue Without Template") {
                // Compose a blank email using just the prospect's email
                EmailComposer.compose(
                    to: controller.prospect.contactEmail,
                    subject: "",
                    body: ""
                )
                onClose()
            }
            .padding(.top, 8)
            .foregroundStyle(.blue)
            .fontWeight(.semibold)

            Button("Create New Template") {
                showCreateTemplate = true
            }
            .padding(.top, 4)
        }
    }
    
}
