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
    var knockCount: Int { get set }
    var contactEmail: String { get set }
    var contactPhone: String { get set }
    
    var notes: [Note] { get set }
    var appointments: [Appointment] { get set }
    var knockHistory: [Knock] { get set }
    var phoneCalls: [PhoneCall] { get set }
}

extension ContactProtocol {
    var sortedKnocks: [Knock] {
        knockHistory.sorted(by: { $0.date > $1.date })
    }
}

extension ContactProtocol {

    var phoneCallCount: Int {
        phoneCalls.count
    }

    var lastPhoneCallDate: Date? {
        phoneCalls
            .sorted(by: { $0.date > $1.date })
            .first?
            .date
    }
}
