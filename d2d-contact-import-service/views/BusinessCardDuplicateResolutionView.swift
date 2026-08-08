//
//  BusinessCardDuplicateResolutionView.swift
//  d2d-studio
//
//  Created by OpenAI on 8/8/26.
//

import SwiftUI

enum BusinessCardDuplicateCandidate: Identifiable {
    case prospect(Prospect)
    case customer(Customer)

    var id: String {
        switch self {
        case .prospect(let prospect):
            "prospect-\(prospect.uuid.uuidString)"
        case .customer(let customer):
            "customer-\(customer.uuid.uuidString)"
        }
    }

    var fullName: String {
        switch self {
        case .prospect(let prospect):
            prospect.fullName
        case .customer(let customer):
            customer.fullName
        }
    }

    var contactPhone: String {
        switch self {
        case .prospect(let prospect):
            prospect.contactPhone
        case .customer(let customer):
            customer.contactPhone
        }
    }

    var contactEmail: String {
        switch self {
        case .prospect(let prospect):
            prospect.contactEmail
        case .customer(let customer):
            customer.contactEmail
        }
    }

    var address: String {
        switch self {
        case .prospect(let prospect):
            prospect.address
        case .customer(let customer):
            customer.address
        }
    }

    var listName: String {
        switch self {
        case .prospect:
            "Prospect"
        case .customer:
            "Customer"
        }
    }
}

enum BusinessCardMergeField: String, CaseIterable, Identifiable {
    case fullName
    case email
    case phone
    case address

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullName:
            "Name"
        case .email:
            "Email"
        case .phone:
            "Phone"
        case .address:
            "Address"
        }
    }
}

struct BusinessCardDuplicateResolutionView: View {
    let draft: ProspectDraft
    let candidates: [BusinessCardDuplicateCandidate]
    let onAddNew: () -> Void
    let onUpdateExisting: (BusinessCardDuplicateCandidate, Set<BusinessCardMergeField>) -> Void
    let onViewExisting: (BusinessCardDuplicateCandidate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCandidateID: String?
    @State private var selectedFields = Set(BusinessCardMergeField.allCases)

    private var selectedCandidate: BusinessCardDuplicateCandidate? {
        if let selectedCandidateID,
           let candidate = candidates.first(where: { $0.id == selectedCandidateID }) {
            return candidate
        }

        return candidates.first
    }

    private var mergeableFields: [BusinessCardMergeField] {
        BusinessCardMergeField.allCases.filter { !draftValue(for: $0).isBusinessCardEmptyValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Potential duplicate")
                            .font(.headline)

                        ForEach(candidates) { candidate in
                            candidateButton(candidate)
                        }
                    }

                    if let selectedCandidate {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Use scanned card values")
                                .font(.headline)

                            ForEach(mergeableFields) { field in
                                fieldToggle(field, candidate: selectedCandidate)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Duplicate Contact")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                actionBar
                    .padding()
                    .background(.bar)
            }
            .onAppear {
                selectedCandidateID = selectedCandidateID ?? candidates.first?.id
                selectedFields = Set(mergeableFields)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This card looks like someone already in your CRM.")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Add it as a new prospect, open the existing contact, or choose which scanned fields should replace the current values.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func candidateButton(_ candidate: BusinessCardDuplicateCandidate) -> some View {
        Button {
            selectedCandidateID = candidate.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedCandidate?.id == candidate.id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedCandidate?.id == candidate.id ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.fullName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(candidateSubtitle(candidate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(candidate.listName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func fieldToggle(_ field: BusinessCardMergeField, candidate: BusinessCardDuplicateCandidate) -> some View {
        Toggle(isOn: binding(for: field)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(field.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Current: \(existingValue(for: field, in: candidate).displayBusinessCardValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text("Scanned: \(draftValue(for: field).displayBusinessCardValue)")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(2)
            }
        }
        .toggleStyle(.switch)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button("Add New") {
                    onAddNew()
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Open Existing") {
                    guard let selectedCandidate else { return }
                    onViewExisting(selectedCandidate)
                    dismiss()
                }
                .buttonStyle(.bordered)
            }

            Button("Update Existing") {
                guard let selectedCandidate else { return }
                onUpdateExisting(selectedCandidate, selectedFields)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedCandidate == nil || selectedFields.isEmpty)
        }
    }

    private func binding(for field: BusinessCardMergeField) -> Binding<Bool> {
        Binding(
            get: { selectedFields.contains(field) },
            set: { isSelected in
                if isSelected {
                    selectedFields.insert(field)
                } else {
                    selectedFields.remove(field)
                }
            }
        )
    }

    private func candidateSubtitle(_ candidate: BusinessCardDuplicateCandidate) -> String {
        [candidate.contactPhone, candidate.contactEmail, candidate.address]
            .filter { !$0.isBusinessCardEmptyValue }
            .joined(separator: " • ")
    }

    private func draftValue(for field: BusinessCardMergeField) -> String {
        switch field {
        case .fullName:
            draft.fullName
        case .email:
            draft.email
        case .phone:
            draft.phone
        case .address:
            draft.address
        }
    }

    private func existingValue(for field: BusinessCardMergeField, in candidate: BusinessCardDuplicateCandidate) -> String {
        switch field {
        case .fullName:
            candidate.fullName
        case .email:
            candidate.contactEmail
        case .phone:
            candidate.contactPhone
        case .address:
            candidate.address
        }
    }
}

private extension String {
    var isBusinessCardEmptyValue: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "Unknown" || trimmed == "No Address"
    }

    var displayBusinessCardValue: String {
        isBusinessCardEmptyValue ? "Not set" : self
    }
}
