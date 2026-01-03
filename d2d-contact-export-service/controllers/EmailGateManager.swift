//
//  EmailGateManager.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/2/26.
//

import Foundation
import Combine

@MainActor
final class EmailGateManager: ObservableObject {
    static let shared = EmailGateManager()
    private init() {
        email = UserDefaults.standard.string(forKey: key)
    }

    @Published private(set) var email: String?

    private let key = "export_gate_email"

    var isUnlocked: Bool {
        email?.isEmpty == false
    }

    func unlock(with email: String) {
        self.email = email
        UserDefaults.standard.set(email, forKey: key)
    }
}
