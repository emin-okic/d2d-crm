//
//  RecordingTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/6/26.
//

import XCTest
@testable import d2d_studio

final class RecordingTests: XCTestCase {

    func testRecordingInitialization() {
        // Arrange
        let fileName = "test_recording.m4a"
        let title = "Test Recording"
        let date = Date()
        let objection = Objection(text: "Not Interested", response: "Sample response", timesHeard: 0)
        let rating = 4

        // Act
        let recording = Recording(
            fileName: fileName,
            title: title,
            date: date,
            objection: objection,
            rating: rating
        )

        // Assert
        XCTAssertEqual(recording.fileName, fileName)
        XCTAssertEqual(recording.title, title)
        XCTAssertEqual(recording.date, date)
        XCTAssertEqual(recording.objection?.text, objection.text)
        XCTAssertEqual(recording.rating, rating)
    }

    func testRecordingDefaultRatingIsNil() {
        // Arrange
        let recording = Recording(
            fileName: "no_rating.m4a",
            title: "No Rating",
            date: Date(),
            objection: nil
        )

        // Assert
        XCTAssertNil(recording.rating)
    }
}
