//
//  BusinessCardConfirmView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI

struct BusinessCardConfirmView: View {
    let draft: ProspectDraft
    let duplicate: BusinessCardDuplicateCandidate?
    let onConfirm: (ProspectDraft) -> Void
    let onUpdateExisting: (BusinessCardDuplicateCandidate, Set<BusinessCardMergeField>) -> Void
    let onOpenExisting: (BusinessCardDuplicateCandidate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var duplicateStep: DuplicateStep = .review
    @State private var selectedMergeFields: Set<BusinessCardMergeField> = []

    init(
        draft: ProspectDraft,
        duplicate: BusinessCardDuplicateCandidate? = nil,
        onConfirm: @escaping (ProspectDraft) -> Void,
        onUpdateExisting: @escaping (BusinessCardDuplicateCandidate, Set<BusinessCardMergeField>) -> Void = { _, _ in },
        onOpenExisting: @escaping (BusinessCardDuplicateCandidate) -> Void = { _ in }
    ) {
        self.draft = draft
        self.duplicate = duplicate
        self.onConfirm = onConfirm
        self.onUpdateExisting = onUpdateExisting
        self.onOpenExisting = onOpenExisting
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let duplicate {
                        switch duplicateStep {
                        case .review:
                            duplicateReviewContent(duplicate)
                        case .replaceFields:
                            replaceFieldsContent(duplicate)
                        }
                    } else {
                        uniqueContent
                    }
                }
                .padding(20)
                .padding(.bottom, duplicate == nil ? 0 : 20)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if duplicateStep == .replaceFields {
                        Button("Back") {
                            duplicateStep = .review
                        }
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                selectedMergeFields = Set(replaceableFields(for: duplicate))
            }
            .onChange(of: duplicateStep) { _, newValue in
                if newValue == .replaceFields {
                    selectedMergeFields = Set(replaceableFields(for: duplicate))
                }
            }
        }
    }

    private var navigationTitle: String {
        guard duplicate != nil else { return "Confirm Prospect" }

        switch duplicateStep {
        case .review:
            return "Possible Duplicate"
        case .replaceFields:
            return "Replace Fields"
        }
    }

    private var uniqueContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            scannedCardSection

            Button {
                onConfirm(draft)
                dismiss()
            } label: {
                Label("Add Prospect", systemImage: "person.crop.circle.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func duplicateReviewContent(_ duplicate: BusinessCardDuplicateCandidate) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Possible duplicate found", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Text("This scanned card matches an existing \(duplicate.subtitle.lowercased()). Choose whether to update the existing contact or add a separate prospect.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            duplicateSummary(duplicate)
            scannedCardSection
            duplicateActions(duplicate)
        }
    }

    private func replaceFieldsContent(_ duplicate: BusinessCardDuplicateCandidate) -> some View {
        let fields = replaceableFields(for: duplicate)

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Fields to Replace")
                    .font(.title3.weight(.semibold))

                Text("Only fields with new values different from the existing contact are shown.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            duplicateSummary(duplicate)

            if fields.isEmpty {
                ContentUnavailableView(
                    "No New Fields",
                    systemImage: "checkmark.seal",
                    description: Text("The scanned card does not have any usable values that differ from this contact.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(fields) { field in
                        mergeFieldRow(field, duplicate: duplicate)
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Apply Updates") {
                    onUpdateExisting(duplicate, selectedMergeFields)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(selectedMergeFields.isEmpty)
            }
        }
    }

    private var scannedCardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scanned Card")
                .font(.headline)

            contactRow(title: "Name", value: draft.fullName, systemImage: "person")
            contactRow(title: "Email", value: draft.email, systemImage: "envelope")
            contactRow(title: "Phone", value: draft.phone, systemImage: "phone")
            contactRow(title: "Address", value: draft.address, systemImage: "mappin.and.ellipse")
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func duplicateSummary(_ duplicate: BusinessCardDuplicateCandidate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: duplicate.type == .prospect ? "person.text.rectangle" : "person.crop.square.filled.and.at.rectangle")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(duplicate.title)
                        .font(.headline)
                    Text(duplicate.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            contactRow(title: "Email", value: duplicate.email, systemImage: "envelope")
            contactRow(title: "Phone", value: duplicate.phone, systemImage: "phone")
            contactRow(title: "Address", value: duplicate.address, systemImage: "mappin.and.ellipse")
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func duplicateActions(_ duplicate: BusinessCardDuplicateCandidate) -> some View {
        VStack(spacing: 12) {
            Button {
                duplicateStep = .replaceFields
            } label: {
                actionButtonContent(
                    title: "Edit Existing",
                    subtitle: "Review which scanned fields replace saved values",
                    systemImage: "arrow.triangle.2.circlepath"
                )
            }
            .buttonStyle(.plain)
            .disabled(replaceableFields(for: duplicate).isEmpty)
            .opacity(replaceableFields(for: duplicate).isEmpty ? 0.55 : 1)

            HStack(spacing: 12) {
                Button {
                    onOpenExisting(duplicate)
                    dismiss()
                } label: {
                    compactActionContent(title: "Open", systemImage: "arrow.up.forward.app")
                }
                .buttonStyle(.plain)

                Button {
                    onConfirm(draft)
                    dismiss()
                } label: {
                    compactActionContent(title: "Add New", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func actionButtonContent(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.accentColor))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func compactActionContent(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.primary.opacity(0.08))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func mergeFieldRow(_ field: BusinessCardMergeField, duplicate: BusinessCardDuplicateCandidate) -> some View {
        let isSelected = selectedMergeFields.contains(field)
        let newValue = field.value(from: draft)

        return Button {
            toggle(field)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 5) {
                    Text(field.title)
                        .font(.subheadline.weight(.semibold))
                    Text("Current: \(displayValue(field.existingValue(from: duplicate)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("New: \(newValue)")
                        .font(.caption)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue.opacity(0.5) : Color.primary.opacity(0.08))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func contactRow(title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(displayValue(value))
                    .font(.subheadline)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 0)
        }
    }

    private func replaceableFields(for duplicate: BusinessCardDuplicateCandidate?) -> [BusinessCardMergeField] {
        guard let duplicate else { return [] }

        return BusinessCardMergeField.allCases.filter { field in
            field.isUsableValue(from: draft) && !field.hasSameValue(draft: draft, duplicate: duplicate)
        }
    }

    private func toggle(_ field: BusinessCardMergeField) {
        if selectedMergeFields.contains(field) {
            selectedMergeFields.remove(field)
        } else {
            selectedMergeFields.insert(field)
        }
    }

    private func displayValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Not set" : trimmed
    }
}

private enum DuplicateStep {
    case review
    case replaceFields
}
