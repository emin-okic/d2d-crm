//
//  AddressParts.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import Foundation

struct AddressParts {
    let base: String
    let unit: String?

    var baseKey: String {
        AddressCanonicalizer.normalizedBaseKey(base)
    }

    var identityKey: String {
        "\(baseKey)|\(unit ?? "")"
    }

    var standardizedAddress: String {
        guard let unit else { return base }
        return AddressCanonicalizer.appendingUnit(unit, to: base)
    }
}

enum AddressCanonicalizer {
    private static let secondaryAddressPattern = #"(?i)(?:[\s,]+)(?:unit|apartment|apt\.?|suite|ste\.?|flat|room|rm\.?|lot|#)\s*#?\s*([\p{L}\p{N}][\p{L}\p{N}-]*)(?=\s*,|\s*$)"#

    static func parse(_ address: String) -> AddressParts {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let expression = try? NSRegularExpression(pattern: secondaryAddressPattern),
              let match = expression.firstMatch(
                in: trimmed,
                range: NSRange(trimmed.startIndex..., in: trimmed)
              ),
              let fullRange = Range(match.range(at: 0), in: trimmed),
              let unitRange = Range(match.range(at: 1), in: trimmed) else {
            return AddressParts(base: normalizedDisplayAddress(trimmed), unit: nil)
        }

        let unit = canonicalUnit(String(trimmed[unitRange]))
        var base = trimmed
        base.removeSubrange(fullRange)

        return AddressParts(
            base: normalizedDisplayAddress(base),
            unit: unit.isEmpty ? nil : unit
        )
    }

    static func canonicalUnit(_ unit: String) -> String {
        unit
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "#")))
            .uppercased()
    }

    static func standardizedAddress(_ address: String) -> String {
        parse(address).standardizedAddress
    }

    static func appendingUnit(_ unit: String, to baseAddress: String) -> String {
        let canonicalUnit = canonicalUnit(unit)
        guard !canonicalUnit.isEmpty else { return normalizedDisplayAddress(baseAddress) }

        let base = normalizedDisplayAddress(baseAddress)
        if let commaIndex = base.firstIndex(of: ",") {
            return "\(base[..<commaIndex]) Unit \(canonicalUnit)\(base[commaIndex...])"
        }

        return "\(base) Unit \(canonicalUnit)"
    }

    static func normalizedBaseKey(_ address: String) -> String {
        normalizedDisplayAddress(address)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    static func addressesMatch(_ lhs: String, _ rhs: String) -> Bool {
        parse(lhs).identityKey == parse(rhs).identityKey
    }

    private static func normalizedDisplayAddress(_ address: String) -> String {
        address
            .replacingOccurrences(of: #"\s+,"#, with: ",", options: .regularExpression)
            .replacingOccurrences(of: #",\s*"#, with: ", ", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",")))
    }
}

func parseAddress(_ address: String) -> AddressParts {
    AddressCanonicalizer.parse(address)
}
