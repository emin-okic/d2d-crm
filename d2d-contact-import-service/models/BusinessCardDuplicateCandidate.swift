//
//  BusinessCardDuplicateCandidate.swift
//  d2d-studio
//

import Foundation

enum BusinessCardDuplicateContactType {
    case prospect
    case customer
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
