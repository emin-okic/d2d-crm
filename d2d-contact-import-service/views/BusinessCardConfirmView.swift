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
    @State private var isPickingMergeFields = false
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
                        duplicateContent(duplicate)
                    } else {
                        uniqueContent
                    }
                }
                .padding(20)
            }
            .navigationTitle(duplicate == nil ? "Confirm Prospect" : "Possible Duplicate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedMergeFields = defaultMergeFields()
            }
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

    private func duplicateContent(_ duplicate: BusinessCardDuplicateCandidate) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("This card looks like an existing \(duplicate.subtitle.lowercased()).", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            duplicateSummary(duplicate)
            scannedCardSection

            if isPickingMergeFields {
                mergeFieldPicker(for: duplicate)
            } else {
                duplicateActions(duplicate)
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
                isPickingMergeFields = true
            } label: {
                Label("Edit Existing Contact", systemImage: "square.and.pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                onOpenExisting(duplicate)
                dismiss()
            } label: {
                Label("Open Existing Contact", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                onConfirm(draft)
                dismiss()
            } label: {
                Label("Add as New Prospect", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func mergeFieldPicker(for duplicate: BusinessCardDuplicateCandidate) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose fields to replace")
                .font(.headline)

            ForEach(BusinessCardMergeField.allCases) { field in
                let newValue = field.value(from: draft)
                if field.isUsableValue(from: draft) {
                    Button {
                        toggle(field)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: selectedMergeFields.contains(field) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedMergeFields.contains(field) ? .blue : .secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(field.title)
                                    .font(.subheadline.weight(.semibold))
                                Text("Current: \(displayValue(field.existingValue(from: duplicate)))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Card: \(newValue)")
                                    .font(.caption)
                            }

                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                Button("Back") {
                    isPickingMergeFields = false
                }
                .buttonStyle(.bordered)

                Button("Apply Updates") {
                    onUpdateExisting(duplicate, selectedMergeFields)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedMergeFields.isEmpty)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private func defaultMergeFields() -> Set<BusinessCardMergeField> {
        Set(BusinessCardMergeField.allCases.filter { field in
            field.isUsableValue(from: draft)
        })
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
