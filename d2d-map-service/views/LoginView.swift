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

            Button(action: {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else {
                    print("❌ No root view controller found.")
                    return
                }

                AuthManager.shared.authorize(presentingViewController: rootVC)

                // Use a delay or callback trigger to switch after login
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if AuthManager.shared.authState?.isAuthorized == true {
                        session.isSignedIn = true
                    }
                }

            }) {
                Text("Sign In with Cognito")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }
}
