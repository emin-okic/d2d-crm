//
//  ImportedContactAddressFormatter.swift
//  d2d-studio
//

import Contacts
import Foundation
import MapKit

enum ImportedContactAddressFormatter {
    static func singleLineAddress(from postalAddress: CNPostalAddress) -> String {
        let street = normalizedMultiline(postalAddress.street)
        let city = normalized(postalAddress.city)
        let statePostalCode = [
            normalized(postalAddress.state),
            normalized(postalAddress.postalCode)
        ]
        .filter { !$0.isEmpty }
        .joined(separator: " ")
        let country = normalized(postalAddress.country).isEmpty
            ? countryName(for: postalAddress.isoCountryCode)
            : normalized(postalAddress.country)

        let address = [street, city, statePostalCode, country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        if !address.isEmpty {
            return address
        }

        return CNPostalAddressFormatter
            .string(from: postalAddress, style: .mailingAddress)
            .replacingOccurrences(of: "\n", with: ", ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func singleLineAddress(for mapItem: MKMapItem, fallback: String) -> String {
        if let fullAddress = mapItem.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true) {
            return fullAddress
        }

        if let fullAddress = mapItem.address?.fullAddress {
            return normalizedSingleLine(fullAddress)
        }

        return normalizedSingleLine(mapItem.name ?? fallback)
    }

    static func normalizedSingleLine(_ address: String) -> String {
        address
            .components(separatedBy: .newlines)
            .map(normalized)
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private static func normalizedMultiline(_ value: String) -> String {
        value
            .components(separatedBy: .newlines)
            .map(normalized)
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private static func normalized(_ value: String) -> String {
        value
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func countryName(for countryCode: String) -> String {
        let trimmed = countryCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        return Locale.current.localizedString(forRegionCode: trimmed.uppercased()) ?? trimmed.uppercased()
    }
}
