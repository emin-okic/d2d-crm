//
//  ResponseGenerator.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//


import Foundation

@MainActor
class ResponseGenerator {
    static let shared = ResponseGenerator()

    func generate(for objection: String) async -> String {
        let prompt = "Generate a three-sentence ARC sales response to this objection: \"\(objection)\""
        // ARC-like placeholder — swap in your actual ML model logic here
        return await runLocalML(prompt: prompt)
    }

    private func runLocalML(prompt: String) async -> String {
        let templates = [
            "I get it. Most folks were unsure too—until they saw how much it helped. Can I show you what I mean real quick?",
            "Totally fair. But just 30 seconds might change your mind. Can I share something fast?",
            "Of course. You’re not the only one who felt that way initially. But here’s why it might be worth it..."
        ]
        return templates.randomElement()!
    }
}
