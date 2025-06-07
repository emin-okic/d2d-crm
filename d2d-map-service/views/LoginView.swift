//
//  LoginView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import SwiftUI
import Foundation
import SwiftData

/// A login screen that allows users to sign in using an email and password.
///
/// If login is successful, the view sets `isLoggedIn` to true to transition to the main app.
/// Includes a link to a `CreateAccountView` for new user registration.
struct LoginView: View {
    /// Tracks whether the user has successfully logged in.
    @Binding var isLoggedIn: Bool

    /// Email input bound from the parent context.
    @Binding var emailInput: String

    /// Password entered by the user.
    @State private var passwordInput: String = ""

    /// Optional error message shown when login fails.
    @State private var errorMessage: String?

    /// Controls whether the Create Account sheet is shown.
    @State private var showCreateAccount = false

    /// The SwiftData model context used for fetching user records.
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)

            // Email input field
            TextField("Email", text: $emailInput)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            // Password input field
            SecureField("Password", text: $passwordInput)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            // Show error if login fails
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            // Trigger login flow
            Button("Login") {
                login()
            }
            .padding()

            // Show Create Account sheet
            Button("Create Account") {
                showCreateAccount = true
            }
            .sheet(isPresented: $showCreateAccount) {
                CreateAccountView(isLoggedIn: $isLoggedIn, emailInput: $emailInput)
            }
        }
        .padding()
    }

    /// Attempts to authenticate the user using the provided email and password.
    ///
    /// If successful, updates the `isLoggedIn` state. Otherwise, shows an error message.
    private func login() {
        let trimmedEmail = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = passwordInput.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            // Look for a user that matches the email and password
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate {
                    $0.email == trimmedEmail && $0.password == trimmedPassword
                }
            )

            let results = try context.fetch(descriptor)

            // If user found, login succeeds
            if let _ = results.first {
                isLoggedIn = true
            } else {
                errorMessage = "Invalid email or password"
            }

        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
        }
    }
}
