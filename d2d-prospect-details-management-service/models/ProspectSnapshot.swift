//
//  ProspectSnapshot.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//

import Foundation

/// Immutable snapshot used to detect Prospect edits
struct ProspectSnapshot: Equatable {
    let fullName: String
    let address: String
    let phone: String
    let email: String
    let list: String

    init(from prospect: Prospect) {
        self.fullName = prospect.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.address = prospect.address.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phone = prospect.contactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = prospect.contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        self.list = prospect.list
    }
}
