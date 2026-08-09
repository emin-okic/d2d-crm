//
//  BusinessCardDuplicateCandidate.swift
//  d2d-studio
//

import Foundation

enum BusinessCardDuplicateContactType {
    case prospect
    case customer
}

struct BusinessCardReview: Identifiable {
    let id = UUID()
    let draft: ProspectDraft
    let duplicate: BusinessCardDuplicateCandidate?
}

struct BusinessCardDuplicateCandidate: Identifiable {
    let id = UUID()
    let type: BusinessCardDuplicateContactType
    let prospect: Prospect?
    let customer: Customer?

    init(prospect: Prospect) {
        self.type = .prospect
        self.prospect = prospect
        self.customer = nil
    }

    init(customer: Customer) {
        self.type = .customer
        self.prospect = nil
        self.customer = customer
    }

    var title: String {
        contact?.fullName ?? "Existing Contact"
    }

    var subtitle: String {
        switch type {
        case .prospect:
            return "Prospect"
        case .customer:
            return "Customer"
        }
    }

    var contact: (any ContactProtocol)? {
        prospect ?? customer
    }

    var address: String {
        contact?.address ?? ""
    }

    var phone: String {
        contact?.contactPhone ?? ""
    }

    var email: String {
        contact?.contactEmail ?? ""
    }
}

enum BusinessCardMergeField: String, CaseIterable, Identifiable {
    case name
    case email
    case phone
    case address

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name:
            return "Name"
        case .email:
            return "Email"
        case .phone:
            return "Phone"
        case .address:
            return "Address"
        }
    }

    func value(from draft: ProspectDraft) -> String {
        switch self {
        case .name:
            return draft.fullName
        case .email:
            return draft.email
        case .phone:
            return draft.phone
        case .address:
            return draft.address
        }
    }

    func isUsableValue(from draft: ProspectDraft) -> Bool {
        let value = value(from: draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return false }

        switch self {
        case .name:
            return value.lowercased() != "unknown" && value.split(separator: " ").count >= 2
        case .address:
            let normalizedValue = value.lowercased().replacingOccurrences(of: " ", with: "")
            return normalizedValue != "noaddress"
        case .email, .phone:
            return true
        }
    }

    func existingValue(from duplicate: BusinessCardDuplicateCandidate) -> String {
        switch self {
        case .name:
            return duplicate.title
        case .email:
            return duplicate.email
        case .phone:
            return duplicate.phone
        case .address:
            return duplicate.address
        }
    }
}
