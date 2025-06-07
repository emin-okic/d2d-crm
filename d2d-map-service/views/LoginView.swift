//
//  LoginView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import SwiftUI
import Foundation
import SwiftData
import CryptoKit

/// A login screen that allows users to sign in using an email and password.
///
/// If login is successful, the view sets `isLoggedIn` to true to transition to the main app.
/// Includes a link to a `CreateAccountView` for new user registration.
struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var emailInput: String

    @State private var passwordInput: String = ""
    @State private var errorMessage: String?
    @State private var showCreateAccount = false

    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)

            TextField("Email", text: $emailInput)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            SecureField("Password", text: $passwordInput)
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

            Button("Login") {
                login()
            }
            .padding()

            Button("Create Account") {
                showCreateAccount = true
            }
            .sheet(isPresented: $showCreateAccount) {
                CreateAccountView(isLoggedIn: $isLoggedIn, emailInput: $emailInput)
            }
        }
        .padding()
    }

    private func login() {
        let trimmedEmail = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = passwordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let hashedInput = sha256Hash(trimmedPassword)

        do {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate {
                    $0.email == trimmedEmail && $0.password == hashedInput
                }
            )
            let results = try context.fetch(descriptor)

            if results.first != nil {
                isLoggedIn = true
            } else {
                errorMessage = "Invalid email or password"
            }

        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
        }
    }

    private func sha256Hash(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
