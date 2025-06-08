//
//  VerifyCodeView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/8/25.
//

import SwiftUI
import Foundation

struct VerifyCodeView: View {
    let email: String
    let expectedCode: String
    var onVerified: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var inputCode: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Verify Email")
                .font(.title2)
                .bold()

            Text("Enter the 6-digit code sent to \(email)")
                .font(.subheadline)
                .multilineTextAlignment(.center)

            TextField("123456", text: $inputCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Verify") {
                verifyCode()
            }
            .padding()
        }
        .padding()
    }

    private func verifyCode() {
        if inputCode == expectedCode {
            let hashedPassword = PasswordController.hash("temp") // replace with actual stored password
            let user = User(email: email, password: hashedPassword)
            context.insert(user)
            try? context.save()
            onVerified()
            dismiss()
        } else {
            errorMessage = "Invalid code. Try again."
        }
    }
}
