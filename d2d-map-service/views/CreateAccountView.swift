//
//  CreateAccountView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import SwiftUI
import SwiftData

/// A SwiftUI view that allows users to create a new account.
///
/// The view handles form input, performs validation, and stores new users in the SwiftData model.
/// On successful account creation, it logs the user in and dismisses the view.
struct CreateAccountView: View {
    /// The model context for inserting and saving new users.
    @Environment(\.modelContext) private var context
    /// Used to dismiss the view upon success.
    @Environment(\.dismiss) private var dismiss

    /// Binding to toggle login state upon successful signup.
    @Binding var isLoggedIn: Bool
    /// Binding for sharing email input with other views (e.g., LoginView).
    @Binding var emailInput: String

    /// User-entered password.
    @State private var password: String = ""
    /// (Optional) confirm password field, currently unused.
    @State private var confirmPassword: String = ""
    /// Displays validation or creation error messages.
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)

            // Email input field
            TextField("Email", text: $emailInput)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            // Password input field
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .textContentType(.password)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            // Display any error messages
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            // Create Account Button
            Button("Create Account") {
                createAccount()
            }
            .padding()
        }
        .padding()
    }

    /// Attempts to create a new account using the provided email and password.
    ///
    /// - Validates input fields.
    /// - Checks if a user with the same email already exists.
    /// - Inserts the new user and logs them in if successful.
    private func createAccount() {
        let trimmedEmail = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Email and password must not be empty"
            return
        }

        do {
            // Check for existing user
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.email == trimmedEmail }
            )
            let existingUsers = try context.fetch(descriptor)

            if !existingUsers.isEmpty {
                errorMessage = "An account with this email already exists"
                return
            }

            // Create and insert new user
            let newUser = User(email: trimmedEmail, password: trimmedPassword)
            context.insert(newUser)
            try context.save()

            // Update login state and dismiss view
            isLoggedIn = true
            dismiss()

        } catch {
            errorMessage = "Account creation failed: \(error.localizedDescription)"
        }
    }
}
