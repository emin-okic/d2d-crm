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
    
    /// Normalizes a phone number for comparison / change detection
    static func normalized(_ value: String?) -> String {
        value?.filter(\.isNumber) ?? ""
    }
    
    /// Formats a raw phone number as (XXX) XXX-XXXX if possible
    static func formatted(_ raw: String) -> String {
        
        let digits = raw.filter(\.isNumber)
        
        guard digits.count == 10 else { return raw }
        
        return "(\(digits.prefix(3))) \(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
    }
}
