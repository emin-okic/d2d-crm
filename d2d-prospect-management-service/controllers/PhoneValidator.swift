//
//  PhoneValidator.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//
import Foundation
import PhoneNumberKit


struct PhoneValidator {
    static func validate(_ raw: String) -> String? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        
        let utility = PhoneNumberUtility()
        do {
            _ = try utility.parse(cleaned)
            return nil // valid
        } catch {
            return "Invalid phone number."
        }
    }
}
