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

        do {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.email == trimmedEmail }
            )
            let existingUsers = try context.fetch(descriptor)

            if !existingUsers.isEmpty {
                errorMessage = "An account with this email already exists"
                return
            }

            let hashedPassword = PasswordController.hash(trimmedPassword)
            let newUser = User(email: trimmedEmail, password: hashedPassword)
            context.insert(newUser)
            try context.save()

            // Send email in background
            sendSignupEmailNotification(for: trimmedEmail)

            isLoggedIn = true
            dismiss()

        } catch {
            errorMessage = "Account creation failed: \(error.localizedDescription)"
        }
    }

    private func sendSignupEmailNotification(for email: String) {
        guard let url = URL(string: "your-url") else {
            print("❌ Invalid email endpoint URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = [
            "subject": "New User Signup",
            "body": "\(email)",
            "recipient": "emin.okic1729@gmail.com"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("❌ Failed to encode JSON payload: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Failed to send email: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("📩 Email API response: \(httpResponse.statusCode)")
            }
        }.resume()
    }
}
