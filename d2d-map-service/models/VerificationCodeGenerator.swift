//
//  VerificationCodeGenerator.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/8/25.
//


import Foundation

enum VerificationCodeGenerator {
    /// Generates a random 6-digit verification code as a string.
    static func generate() -> String {
        return String(format: "%06d", Int.random(in: 0...999999))
    }
}
