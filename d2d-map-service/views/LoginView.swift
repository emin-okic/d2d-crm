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
                login()
            }
            .padding()
        }
        .padding()
    }

    private func login() {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to get root view controller"
            return
        }

        AuthManager.shared.signIn(presentingViewController: rootVC) { success, error in
            DispatchQueue.main.async {
                if success {
                    isLoggedIn = true
                } else {
                    errorMessage = error
                }
            }
        }
    }
}
