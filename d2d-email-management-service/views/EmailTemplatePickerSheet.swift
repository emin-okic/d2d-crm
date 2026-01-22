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

            ScrollView {
                VStack(spacing: 8) {

                    if templates.isEmpty {
                        emptyState
                    }

                    templateList
                }
            }
        }
        .padding()
        .presentationDetents([.medium]) // ⬅️ important
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showCreateTemplate) {
            CreateEmailTemplateSheet(onSave: { _ in
                showCreateTemplate = false
            })
            .environment(\.modelContext, controller.modelContext)
        }
    }

    private var emptyState: some View {
        Text("No templates yet")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 12)
    }

    private var templateList: some View {
        VStack(spacing: 8) {

            // ✅ Email Without Template button
            Button {
                controller.composeBlankEmail()
                onClose()
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

            // Create new template
            Button("Create New Template") { showCreateTemplate = true }
                .padding(.top, 4)
        }
    }
    
}
