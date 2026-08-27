//
//  ContactRowAddressFormatter.swift
//  d2d-studio
//
//  Created by Codex on 8/26/26.
//

import Foundation

enum ContactRowAddressFormatter {
    static func displayAddress(from address: String) -> String {
        let parts = address
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard parts.count >= 3 else {
            return address.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let street = parts[0]
        let city = parts[1]
        let state = stateCode(from: parts[2])

        guard !street.isEmpty, !city.isEmpty, !state.isEmpty else {
            return address.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return "\(street), \(city), \(state)"
    }

    private static func stateCode(from component: String) -> String {
        component
            .split(separator: " ")
            .first
            .map(String.init) ?? component
    }
}
