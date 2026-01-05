//
//  EmailValidatorTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import XCTest
@testable import d2d_studio

final class EmailValidatorTests: XCTestCase {

    func testValidEmailReturnsNil() {
        // Given
        let email = "user@example.com"

        // When
        let result = EmailValidator.validate(email)

        // Then
        XCTAssertNil(result, "Expected valid email to return nil error")
    }

    func testInvalidFormatReturnsInvalidFormatError() {
        // Given
        let email = "not-an-email"

        // When
        let result = EmailValidator.validate(email)

        // Then
        XCTAssertEqual(result, .invalidFormat)
    }

    func testBlockedDomainReturnsBlockedDomainError() {
        // Given
        let email = "user@tempmail.com" // assume this domain is blocked

        // When
        let result = EmailValidator.validate(email)

        // Then
        XCTAssertEqual(result, .blockedDomain)
    }
}
