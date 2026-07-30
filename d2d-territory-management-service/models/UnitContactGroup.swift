//
//  UnitContactGroup.swift
//  d2d-studio
//

import Foundation

struct UnitContactGroup: Identifiable {
    let unit: String?
    let contacts: [UnitContact]

    var id: String {
        unit ?? "main"
    }

    var contactCount: Int {
        contacts.count
    }

    var hasCustomer: Bool {
        contacts.contains { $0.isCustomer }
    }

    var hasUnqualified: Bool {
        contacts.contains { $0.isUnqualified }
    }

    var knockCount: Int {
        contacts.reduce(0) { $0 + $1.knockCount }
    }

    var primaryContact: UnitContact? {
        contacts.first
    }
}
