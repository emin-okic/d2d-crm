//
//  CreateAccountView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import SwiftUI
import SwiftData

struct CreateAccountView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var isLoggedIn: Bool
    @Binding var emailInput: String

    @State private var password: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)

            TextField("Email", text: $emailInput)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .textContentType(.password)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Create Account") {
                createAccount()
            }
            .padding()
        }
        .padding()
    }

    private func createAccount() {
        let trimmedEmail = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Email and password must not be empty"
            return
        }

        let hashedPassword = PasswordController.hash(trimmedPassword)

        let url = URL(string: "http://127.0.0.1:5000/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = [
            "email": trimmedEmail,
            "password": hashedPassword
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            errorMessage = "Failed to encode request"
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response"
                    return
                }

                if httpResponse.statusCode == 201 {
                    self.isLoggedIn = true
                    self.dismiss()
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let message = json["message"] as? String {
                        self.errorMessage = message
                    } else {
                        self.errorMessage = "Signup failed with status code \(httpResponse.statusCode)"
                    }
                }
            }
        }.resume()
    }
}
