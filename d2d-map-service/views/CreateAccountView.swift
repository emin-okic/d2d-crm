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

    @State private var showVerification = false
    @State private var generatedCode: String?

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
        .sheet(isPresented: $showVerification) {
            if let code = generatedCode {
                VerifyCodeView(
                    email: emailInput,
                    expectedCode: code,
                    onVerified: {
                        isLoggedIn = true
                        dismiss()
                    }
                )
            }
        }
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

            // Send email verification code
            let code = VerificationCodeGenerator.generate()
            BrevoMailer.sendVerification(to: trimmedEmail, code: code)
            generatedCode = code
            showVerification = true

        } catch {
            errorMessage = "Account creation failed: \(error.localizedDescription)"
        }
    }
}
