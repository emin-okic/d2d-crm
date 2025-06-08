//
//  BrevoMailer.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/8/25.
//


import Foundation

enum BrevoMailer {
    static let apiKey = "TODO"
    static let senderEmail = "TODO"
    static let senderName = "D2D CRM"

    static func sendVerification(to email: String, code: String) {
        guard let url = URL(string: "https://api.brevo.com/v3/smtp/email") else { return }

        let body: [String: Any] = [
            "sender": [
                "name": senderName,
                "email": senderEmail
            ],
            "to": [
                ["email": email]
            ],
            "subject": "Your D2D CRM Verification Code",
            "htmlContent": "<p>Your verification code is <strong>\(code)</strong>.</p>"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("api-key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request).resume()
    }
}
