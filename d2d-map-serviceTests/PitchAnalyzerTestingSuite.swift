//
//  PitchAnalyzerTestingSuite.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import XCTest
@testable import d2d_map_service

final class PitchAnalyzerTestingSuite: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPitchAnalyzerScoring() {
        // Given
        let analyzer = PitchAnalyzer()
        let expectedResponse = "Hi"
        let userResponse = "Hi" // Simulate transcription output

        // When
        let score = analyzer.score(user: userResponse, expected: expectedResponse)

        // Then
        XCTAssertEqual(score, 5, "Expected perfect match to score 5 but got \(score)")
    }
    
    func testPitchAnalyzerPartialMatch() {
        let analyzer = PitchAnalyzer()
        let expectedResponse = "Hi how are you"
        let userResponse = "Hi you" // 2 of 4 words match

        let score = analyzer.score(user: userResponse, expected: expectedResponse)

        XCTAssertEqual(score, 3, "Expected partial match to score 3 but got \(score)")
    }

}
