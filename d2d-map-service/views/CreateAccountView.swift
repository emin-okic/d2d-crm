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
        guard !emailInput.isEmpty, !password.isEmpty else {
            errorMessage = "Check that email and passwords are filled and match"
            return
        }

        let newUser = User(email: emailInput, password: password)
        context.insert(newUser)

        do {
            try context.save()
            isLoggedIn = true
            dismiss() // Dismiss to go back to main view
        } catch {
            errorMessage = "Failed to create user: \(error.localizedDescription)"
        }
    }
}
