//
//  PhoneCallRecipientType.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/28/26.
//
import Foundation
import SwiftData

enum PhoneCallRecipientType: String, Codable {
    case prospect
    case customer
}

@Model
final class PhoneCall {

    var id: UUID

    /// When the call was initiated
    var date: Date

    /// Who this call belongs to
    var recipientUUID: UUID
    var recipientType: PhoneCallRecipientType

    init(
        date: Date = .now,
        recipientUUID: UUID,
        recipientType: PhoneCallRecipientType
    ) {
        self.id = UUID()
        self.date = date
        self.recipientUUID = recipientUUID
        self.recipientType = recipientType
    }
}
