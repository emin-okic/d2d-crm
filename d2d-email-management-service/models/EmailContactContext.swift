//
//  EmailContactContext.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/24/26.
//
import Foundation
import SwiftData


struct EmailContactContext {
    
    let id: UUID
    let recipientType: EmailRecipientType
    
    let displayName: String
    let getEmail: () -> String
    let setEmail: (String) -> Void
    let appendNote: (Note) -> Void
}

extension EmailContactContext {
    static func prospect(_ prospect: Prospect) -> EmailContactContext {
        EmailContactContext(
            id: prospect.uuid,
            recipientType: .prospect,
            displayName: prospect.fullName,
            getEmail: { prospect.contactEmail },
            setEmail: { prospect.contactEmail = $0 },
            appendNote: { prospect.notes.append($0) }
        )
    }

    static func customer(_ customer: Customer) -> EmailContactContext {
        EmailContactContext(
            id: customer.uuid,
            recipientType: .customer,
            displayName: customer.fullName,
            getEmail: { customer.contactEmail },
            setEmail: { customer.contactEmail = $0 },
            appendNote: { customer.notes.append($0) }
        )
    }
}
