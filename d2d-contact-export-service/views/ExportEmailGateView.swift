//
//  ExportEmailGateView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/2/26.
//

import SwiftUI

struct ExportEmailGateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showError = false

    let onSuccess: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // MARK: Header / Funnel Step
                VStack(spacing: 8) {
                    Text("Unlock CSV Exports")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Enter your email to gain instant access to your export files. No spam, promise!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // MARK: Email Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    TextField("you@email.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(showError ? Color.red : Color.gray.opacity(0.4), lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    if showError {
                        Text("Please enter a valid email address")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)

                // MARK: Action Button
                Button(action: handleUnlock) {
                    Text("Unlock Export")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(.top, 60)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func handleUnlock() {
        
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let error = EmailValidator.validate(trimmed) {
            
            showError = true
            
            // Error feedback
            ContactScreenHapticsController.shared.lightTap()
            ContactScreenSoundController.shared.playSound1()
            
            // Optional: store error.rawValue to display a specific message
            return
        }
        
        showError = false
        EmailGateManager.shared.unlock(with: trimmed)

        CloudKitEmailLogger.shared.log(
            ExportEmailPayload(
                email: trimmed,
                timestamp: Date(),
                source: "csv_export_gate"
            )
        )
        
        // Success feedback
        ContactScreenHapticsController.shared.successConfirmationTap()
        ContactScreenSoundController.shared.playSound1()

        onSuccess()
        dismiss()
    }
}
