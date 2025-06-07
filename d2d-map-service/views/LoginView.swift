//
//  LoginView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import SwiftUI
import SwiftData
import Foundation

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var emailInput: String

    @State private var passwordInput: String = ""
    @State private var errorMessage: String?

    @State private var showCreateAccount = false
    @State private var showForgotPassword = false

    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 24) {
            // MARK: - Title
            Text("Login")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)

            // MARK: - Credentials
            VStack(spacing: 16) {
                TextField("Email", text: $emailInput)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.username)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                SecureField("Password", text: $passwordInput)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }

            // MARK: - Error Message
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.top, -12)
            }

            // MARK: - Login Button
            Button(action: login) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()

            // MARK: - Secondary Actions
            VStack(spacing: 8) {
                Button("Create Account") {
                    showCreateAccount = true
                }
                .font(.footnote)
                .foregroundColor(.blue)

                Button("Forgot Password?") {
                    showForgotPassword = true
                }
                .font(.footnote)
                .foregroundColor(.gray)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal)
        .sheet(isPresented: $showCreateAccount) {
            CreateAccountView(isLoggedIn: $isLoggedIn, emailInput: $emailInput)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    private func login() {
        let trimmedEmail = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = passwordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let hashedInput = PasswordController.hash(trimmedPassword)

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
}
