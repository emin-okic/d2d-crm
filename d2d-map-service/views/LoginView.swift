//
//  LoginView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/1/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to D2D CRM")
                .font(.title)
                .bold()

            Button("Sign In with Cognito") {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else {
                    print("❌ No root view controller found.")
                    return
                }

                AuthManager.shared.onSignIn = {
                    session.isSignedIn = true // ✅ Actual transition point
                }

                AuthManager.shared.authorize(presentingViewController: rootVC)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}
