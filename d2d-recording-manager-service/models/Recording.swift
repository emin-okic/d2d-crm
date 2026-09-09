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
