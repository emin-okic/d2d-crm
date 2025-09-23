//
//  ContactProtocol.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import Foundation

protocol ContactProtocol {
    var fullName: String { get set }
    var address: String { get set }
    var count: Int { get set }
    var contactEmail: String { get set }
    var contactPhone: String { get set }
    var notes: [Note] { get set }
    var appointments: [Appointment] { get set }
    var knockHistory: [Knock] { get set }
}

extension ContactProtocol {
    var sortedKnocks: [Knock] {
        knockHistory.sorted(by: { $0.date > $1.date })
    }
}
