//
//  RecordingTests.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/6/26.
//

import XCTest
import SwiftData
import Testing
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

    func testPitchAnalyzerRatesCloseMatchHighly() {
        let analyzer = PitchAnalyzer()

        let rating = analyzer.score(
            user: "I understand the price concern, but the long term value is worth it.",
            expected: "I understand the price concern but the long term value is worth it"
        )

        XCTAssertEqual(rating, 5)
    }

    func testPitchAnalyzerReturnsNeedsWorkRatingForEmptyInput() {
        let analyzer = PitchAnalyzer()

        let rating = analyzer.score(user: "", expected: "Here is the expected objection response")

        XCTAssertEqual(rating, 1)
    }
}


@Suite("Objection deletion integrity")
@MainActor
struct ObjectionDeletionTests {
    @Test("Manager deletion removes linked recordings but preserves unrelated recordings")
    func managerDeletionCleansUpOnlyLinkedRecordings() throws {
        let context = try makeContext()
        let deletedObjection = Objection(text: "Too expensive")
        let retainedObjection = Objection(text: "Need to think about it")
        let linkedRecording = Recording(
            fileName: "linked-recording.m4a",
            title: "Linked",
            date: .now,
            objection: deletedObjection
        )
        let unrelatedRecording = Recording(
            fileName: "unrelated-recording.m4a",
            title: "Unrelated",
            date: .now,
            objection: retainedObjection
        )

        context.insert(deletedObjection)
        context.insert(retainedObjection)
        context.insert(linkedRecording)
        context.insert(unrelatedRecording)
        try context.save()

        ObjectionManager().delete(deletedObjection, from: context)

        let objections = try context.fetch(FetchDescriptor<Objection>())
        let recordings = try context.fetch(FetchDescriptor<Recording>())
        #expect(objections.count == 1)
        #expect(objections.first?.text == retainedObjection.text)
        #expect(recordings.count == 1)
        #expect(recordings.first?.title == unrelatedRecording.title)
        #expect(recordings.first?.objection?.text == retainedObjection.text)
    }

    @Test("Relationship cascade protects direct objection deletion")
    func directDeletionDoesNotLeaveDanglingRecording() throws {
        let context = try makeContext()
        let objection = Objection(text: "Not interested")
        let recording = Recording(
            fileName: "cascade-recording.m4a",
            title: "Cascade",
            date: .now,
            objection: objection
        )

        context.insert(objection)
        context.insert(recording)
        try context.save()

        context.delete(objection)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Objection>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Recording>()) == 0)
    }

    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            Prospect.self,
            Customer.self,
            Knock.self,
            Trip.self,
            Objection.self,
            Appointment.self,
            Note.self,
            Recording.self,
            EmailTemplate.self,
            Email.self,
            PhoneCall.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
}
