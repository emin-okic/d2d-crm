//
//  Recording.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//


import Foundation
import SwiftData

@Model
final class Recording {
    var fileName: String
    var date: Date
    var objection: Objection?
    var rating: Int? // New

    init(fileName: String, date: Date, objection: Objection?, rating: Int? = nil) {
        self.fileName = fileName
        self.date = date
        self.objection = objection
        self.rating = rating
    }
}
