//
//  AddressParts.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//


struct AddressParts {
    let base: String
    let unit: String?
}

func parseAddress(_ address: String) -> AddressParts {
    let lower = address.lowercased()

    if let range = lower.range(of: " unit ") {
        let base = String(address[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        let unit = String(address[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        return AddressParts(base: base, unit: unit)
    }

    return AddressParts(base: address, unit: nil)
}
