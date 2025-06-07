//
//  ForgotPasswordView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/7/25.
//

import SwiftUI
import SwiftData

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var email: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reset Password")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button("Update Password") {
                        resetPassword()
                    }
                }
            }
            .navigationTitle("Forgot Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func resetPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNewPassword = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedNewPassword.isEmpty else {
            errorMessage = "All fields are required."
            return
        }

        guard trimmedNewPassword == trimmedConfirm else {
            errorMessage = "Passwords do not match."
            return
        }

        do {
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.email == trimmedEmail }
            )
            if var user = try context.fetch(descriptor).first {
                user.password = PasswordController.hash(trimmedNewPassword)
                try context.save()
                dismiss()
            } else {
                errorMessage = "No account found for that email."
            }
        } catch {
            errorMessage = "Error resetting password: \(error.localizedDescription)"
        }
    }
}
