//
//  Email.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/27/26.
//

import SwiftData
import Foundation

@Model
final class Email {
    var recipientUUID: UUID
    var recipientType: EmailRecipientType

    var templateUUID: UUID?
    var subject: String
    var body: String
    var sentAt: Date

    init(
        recipientUUID: UUID,
        recipientType: EmailRecipientType,
        templateUUID: UUID?,
        subject: String,
        body: String
    ) {
        self.recipientUUID = recipientUUID
        self.recipientType = recipientType
        self.templateUUID = templateUUID
        self.subject = subject
        self.body = body
        self.sentAt = Date()
    }
}

enum EmailRecipientType: String, Codable {
    case prospect
    case customer
}
