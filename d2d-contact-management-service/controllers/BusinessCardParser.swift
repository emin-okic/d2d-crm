//
//  BusinessCardParser.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import Foundation

enum BusinessCardParser {

    static func parse(text: String) -> ProspectDraft {
        let lines = text.components(separatedBy: .newlines)

        let email = lines.first(where: { $0.contains("@") }) ?? ""
        let phone = lines.first(where: { $0.range(of: "\\d{3}.*\\d{4}", options: .regularExpression) != nil }) ?? ""

        let name = lines.first(where: {
            $0.split(separator: " ").count >= 2 &&
            !$0.contains("@") &&
            !$0.contains("www")
        }) ?? "Unknown"

        let address = lines.first(where: {
            $0.range(of: "\\d+\\s+.+", options: .regularExpression) != nil
        }) ?? ""

        return ProspectDraft(
            fullName: name,
            phone: phone,
            email: email,
            address: address
        )
    }
}
