//
//  EmailTemplate.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/21/26.
//

import SwiftData
import Foundation

@Model
final class EmailTemplate: Identifiable {
    var id: UUID
    var title: String
    var subject: String
    var body: String
    var createdAt: Date

    init(title: String, subject: String, body: String) {
        self.id = UUID()
        self.title = title
        self.subject = subject
        self.body = body
        self.createdAt = Date()
    }
}
