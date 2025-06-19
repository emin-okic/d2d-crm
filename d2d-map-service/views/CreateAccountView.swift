//
//  CreateAccountView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import SwiftUI
import SwiftData

struct CreateAccountView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Binding var isLoggedIn: Bool
    @Binding var emailInput: String

    @State private var password: String = ""
    @State private var confirmPassword: String = ""
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

        Task {
            do {
                try await createAccountRequest(email: trimmedEmail, password: trimmedPassword)
                isLoggedIn = true
                dismiss()
            } catch {
                errorMessage = "Account creation failed: \(error.localizedDescription)"
            }
        }
    }

    func createAccountRequest(email: String, password: String) async throws {
        guard let url = URL(string: "http://127.0.0.1:5000/signup") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 201 {
                print("✅ Account created successfully")
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
        }
    }
}
