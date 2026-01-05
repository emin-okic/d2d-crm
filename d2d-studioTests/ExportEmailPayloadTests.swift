//
//  ExportEmailPayloadTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import XCTest
@testable import d2d_studio

final class ExportEmailPayloadTests: XCTestCase {

    func testExportEmailPayloadInitialization() {
        // Given
        let email = "test@example.com"
        let timestamp = Date()
        let source = "csv_export_gate"

        // When
        let payload = ExportEmailPayload(
            email: email,
            timestamp: timestamp,
            source: source
        )

        // Then
        XCTAssertEqual(payload.email, email)
        XCTAssertEqual(payload.source, source)
        XCTAssertEqual(payload.timestamp, timestamp)
    }

    func testExportEmailPayloadTimestampIsRecent() {
        // Given
        let now = Date()

        // When
        let payload = ExportEmailPayload(
            email: "user@test.com",
            timestamp: now,
            source: "csv_export_gate"
        )

        // Then
        XCTAssertLessThanOrEqual(
            payload.timestamp.timeIntervalSince(now),
            0.01,
            "Timestamp should be initialized with a recent Date"
        )
    }
}
