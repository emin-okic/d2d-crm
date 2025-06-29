//
//  Note.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/8/25.
//


// Note.swift

import Foundation
import SwiftData

@Model
class Note {
    var date: Date
    var content: String

    init(content: String, date: Date = Date()) {
        self.date = date
        self.content = content
    }
}
