//
//  CreateAccountView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import SwiftUI
import SwiftData

import CryptoKit

/// A SwiftUI view that allows users to create a new account.
///
/// The view handles form input, performs validation, and stores new users in the SwiftData model.
/// On successful account creation, it logs the user in and dismisses the view.
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

            let hashedPassword = sha256Hash(trimmedPassword)
            let newUser = User(email: trimmedEmail, password: hashedPassword)
            context.insert(newUser)
            try context.save()

            isLoggedIn = true
            dismiss()

        } catch {
            errorMessage = "Account creation failed: \(error.localizedDescription)"
        }
    }

    private func sha256Hash(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
