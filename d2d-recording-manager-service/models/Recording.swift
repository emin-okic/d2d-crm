//
//  Recording.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

import Foundation
import SwiftData

@Model
final class Recording {
    var fileName: String          // immutable disk identifier
    var title: String             // user-editable
    var date: Date
    var objection: Objection?
    var rating: Int?
    var prospect: Prospect?
    var customer: Customer?

    init(
        fileName: String,
        title: String,
        date: Date,
        objection: Objection?,
        rating: Int? = nil,
        prospect: Prospect? = nil,
        customer: Customer? = nil
    ) {
        self.fileName = fileName
        self.title = title
        self.date = date
        self.objection = objection
        self.rating = rating
        self.prospect = prospect
        self.customer = customer
    }
}

extension Recording {
    var associatedContactName: String? {
        prospect?.fullName ?? customer?.fullName
    }

    var associatedContactAddress: String? {
        prospect?.address ?? customer?.address
    }

    var associatedContactType: String? {
        if prospect != nil { return "Prospect" }
        if customer != nil { return "Customer" }
        return nil
    }

    var associatedContactIconName: String {
        customer != nil ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.badge.clock"
    }

    var hasAssociatedContact: Bool {
        prospect != nil || customer != nil
    }
}
