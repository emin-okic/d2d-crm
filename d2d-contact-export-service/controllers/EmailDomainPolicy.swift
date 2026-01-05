//
//  EmailDomainPolicy.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

struct EmailDomainPolicy {
    static let blockedDomains: Set<String> = [
        "mailinator.com",
        "tempmail.com",
        "10minutemail.com",
        "guerrillamail.com"
    ]

    static func isAllowedDomain(_ email: String) -> Bool {
        guard let domain = email.split(separator: "@").last else {
            return false
        }
        return !blockedDomains.contains(domain.lowercased())
    }
}
