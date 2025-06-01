//
//  LoginView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/1/25.
//

import SwiftUI
import AppAuth

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var authState: OIDAuthState?
    
    private let issuer = URL(string: "https://cognito-idp.us-east-2.amazonaws.com/us-east-2_3qKzMckST")!
    private let clientID = "7hkvtmon35nr1qkjnscbvgsosk"
    private let redirectURI = URL(string: "myapp://callback")!
    
    @Environment(\.openURL) var openURL
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some View {
        VStack {
            Text("Welcome to D2D CRM")
                .font(.title)
                .padding()

            Button("Sign in with Cognito") {
                login()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }

    func login() {
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { config, error in
            guard let config = config else {
                print("Discovery failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let request = OIDAuthorizationRequest(
                configuration: config,
                clientId: clientID,
                scopes: [OIDScopeOpenID, OIDScopeProfile, "email"],
                redirectURL: redirectURI,
                responseType: OIDResponseTypeCode,
                additionalParameters: nil
            )

            guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController else {
                print("Missing root VC")
                return
            }

            appDelegate.currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: request,
                presenting: rootVC
            ) { authState, error in
                if let authState = authState {
                    self.authState = authState
                    print("Logged in! Token: \(authState.lastTokenResponse?.accessToken ?? "none")")
                    isLoggedIn = true
                } else {
                    print("Login failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}
