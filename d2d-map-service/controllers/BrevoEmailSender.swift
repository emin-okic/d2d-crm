//
//  BravoEmailSender.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/8/25.
//

import Foundation

struct BrevoEmailSender {
    static let apiKey = "TODO" // 🔐 Keep secret in production
    static let templateId = 1       // 🔁 Replace with your actual numeric template ID
    static let senderEmail = "TODO"
    static let senderName = "D2D CRM"

    static func sendVerification(to email: String, code: String) {
        guard let url = URL(string: "https://api.brevo.com/v3/smtp/email") else {
            print("❌ Invalid Brevo URL")
            return
        }

        let payload: [String: Any] = [
            "sender": [
                "name": senderName,
                "email": senderEmail
            ],
            "to": [
                [
                    "email": email,
                    "name": email  // You can customize this if you have real names
                ]
            ],
            "templateId": templateId,
            "params": [
                "code": code // 🔁 Must match the `{{params.code}}` in your template
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "api-key")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("❌ Failed to encode JSON: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Brevo send failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📬 Brevo response code: \(httpResponse.statusCode)")
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    print("📨 Brevo response body: \(body)")
                }
            } else {
                print("❌ Invalid Brevo response")
            }
        }.resume()
    }
}
