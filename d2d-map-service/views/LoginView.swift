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
        GeometryReader { geometry in
            VStack {
                Spacer(minLength: geometry.size.height * 0.1)

                VStack(spacing: 24) {
                    // MARK: - Title
                    Text("The D2D CRM")
                        .font(.largeTitle)
                        .bold()

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
                }
                .padding(.horizontal)
                
                Spacer()

                // MARK: - Secondary Actions
                VStack(spacing: 12) {
                    Button("Create Account") {
                        showCreateAccount = true
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .padding(.bottom, 4)

                    Button("Forgot Password?") {
                        showForgotPassword = true
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 36)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
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

        Task {
            do {
                let success = try await loginRequest(email: trimmedEmail, password: trimmedPassword)
                if success {
                    isLoggedIn = true
                } else {
                    errorMessage = "Invalid email or password"
                }
            } catch {
                errorMessage = "Login failed: \(error.localizedDescription)"
            }
        }
    }

    func loginRequest(email: String, password: String) async throws -> Bool {
        guard let url = URL(string: "http://127.0.0.1:5000/login") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                print("✅ Login successful")
                return true
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Login failed: \(errorMessage)")
            }
        }

        return false
    }
}
