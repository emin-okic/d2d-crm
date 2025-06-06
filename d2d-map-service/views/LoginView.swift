//
//  LoginView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var emailInput: String = ""
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

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Login") {
                let trimmedEmail = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedEmail.isEmpty {
                    isLoggedIn = true
                } else {
                    errorMessage = "Please enter an email to continue"
                }
            }
            .padding()
        }
        .padding()
    }
}
