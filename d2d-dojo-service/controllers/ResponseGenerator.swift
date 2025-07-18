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
        // Placeholder for ARC/ML model inference logic
        // You could hook into CreateML, a custom transformer model, or even a remote API
        return """
        I totally understand. But many of your neighbors said the same until they saw the benefits. Can I show you one quick thing that'll take 30 seconds?
        """
    }
}
