//
//  PhoneActionContext.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/28/26.
//

import Foundation

struct PhoneActionContext {

    let id: UUID
    let recipientType: PhoneCallRecipientType

    let displayName: String
    let getPhone: () -> String
    let setPhone: (String) -> Void
}

extension PhoneActionContext {

    static func prospect(_ prospect: Prospect) -> PhoneActionContext {
        PhoneActionContext(
            id: prospect.uuid,
            recipientType: .prospect,
            displayName: prospect.fullName,
            getPhone: { prospect.contactPhone },
            setPhone: { prospect.contactPhone = $0 }
        )
    }

    static func customer(_ customer: Customer) -> PhoneActionContext {
        PhoneActionContext(
            id: customer.uuid,
            recipientType: .customer,
            displayName: customer.fullName,
            getPhone: { customer.contactPhone },
            setPhone: { customer.contactPhone = $0 }
        )
    }
}
