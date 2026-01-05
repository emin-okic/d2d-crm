//
//  EmailValidator.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//


struct EmailValidator {
    static func validate(_ email: String) -> EmailValidationError? {
        if !isValidFormat(email) {
            return .invalidFormat
        }
        if !EmailDomainPolicy.isAllowedDomain(email) {
            return .blockedDomain
        }
        return nil
    }

    private static func isValidFormat(_ email: String) -> Bool {
        let pattern =
        #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
