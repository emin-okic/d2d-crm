//
//  PasswordController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/7/25.
//

import CryptoKit
import Foundation

enum PasswordController {
    static func hash(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
