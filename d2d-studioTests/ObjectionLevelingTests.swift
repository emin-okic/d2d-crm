//
//  ObjectionLevelingTests.swift
//  d2d-studioTests
//

import Testing
@testable import d2d_studio

struct ObjectionLevelingTests {
    @Test
    func confidenceUsesFibonacciProgressionAndCapsAtFive() {
        let expectedLevels = [
            0: 1,
            1: 2,
            2: 2,
            3: 3,
            5: 3,
            6: 4,
            10: 4,
            11: 5,
            100: 5
        ]

        for (responseCount, expectedLevel) in expectedLevels {
            let objection = Objection(
                text: "I need to think about it",
                practiceResponseCount: responseCount
            )

            #expect(objection.confidenceLevel == expectedLevel)
        }
    }

    @Test
    func recordingPracticeCountsEveryNonemptySubmission() {
        let objection = Objection(text: "Not interested")

        #expect(objection.recordPracticeResponse("I understand. What is your main concern?"))
        #expect(objection.recordPracticeResponse("I understand. What is your main concern?"))
        #expect(objection.practiceResponseCount == 2)
        #expect(objection.extraResponses.count == 1)
        #expect(objection.confidenceLevel == 2)
        #expect(objection.responsesUntilNextLevel == 2)
    }

    @Test
    func emptyPracticeResponseDoesNotAdvanceProgress() {
        let objection = Objection(text: "Already have a provider")

        #expect(!objection.recordPracticeResponse("   \n"))
        #expect(objection.practiceResponseCount == 0)
        #expect(objection.levelProgress == 0)
    }
}
