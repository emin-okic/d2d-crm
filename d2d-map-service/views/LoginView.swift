//
//  LoginView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var emailInput: String

    @State private var passwordInput: String = ""
    @State private var errorMessage: String?

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

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Login") {
                login()
            }
            .padding()
        }
        .padding()
    }

    private func login() {
        let trimmedEmail = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = passwordInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }

        // ✅ Simulate successful login
        isLoggedIn = true
    }
}
