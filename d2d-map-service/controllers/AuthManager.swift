//
//  AuthManager.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/1/25.
//

import Foundation
import AppAuth
import UIKit

class AuthManager {
    
    static let shared = AuthManager()

    // OIDC config
    let issuer = "https://cognito-idp.us-east-2.amazonaws.com/us-east-2_3qKzMckST"
    let clientID = "7hkvtmon35nr1qkjnscbvgsosk"
    let redirectURI = "https://d84l1y8p4kdic.cloudfront.net"
    let logoutURL = "myapp://logout"

    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    var authState: OIDAuthState?

    private init() {}
    
    func fetchUserInfo() {
        guard
            let userinfoEndpoint = authState?.lastAuthorizationResponse.request.configuration
                .discoveryDocument?.userinfoEndpoint
        else {
            print("Userinfo endpoint not declared in discovery document")
            return
        }

        authState?.performAction { accessToken, idToken, error in
            guard let accessToken = accessToken else {
                print("Error fetching access token: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            var urlRequest = URLRequest(url: userinfoEndpoint)
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    print("UserInfo request failed: \(error)")
                    return
                }

                guard let data = data else {
                    print("No data in userinfo response")
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("✅ User Info: \(json)")
                        // Optional: Store or use the user's name, email, etc.
                    }
                } catch {
                    print("❌ JSON parse error: \(error)")
                }
            }

            task.resume()
        }
    }
    
    func logout() {
        guard
            let endSessionEndpoint = authState?.lastAuthorizationResponse.request.configuration
                .discoveryDocument?.endSessionEndpoint
        else {
            print("EndSession endpoint not declared in discovery document")
            return
        }

        var components = URLComponents(url: endSessionEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "logout_uri", value: logoutURL) // must match what you set in Cognito
        ]

        if let logoutURL = components.url {
            UIApplication.shared.open(logoutURL, options: [:], completionHandler: nil)
        }
    }

    func authorize(presentingViewController: UIViewController) {
        guard let issuerURL = URL(string: issuer) else {
            print("Error creating URL from issuer: \(issuer)")
            return
        }

        // ✅ Discover the .well-known config
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuerURL) { configuration, error in
            guard let config = configuration else {
                print("Error retrieving discovery document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            print("Got discovery configuration: \(config)")

            guard let redirectURL = URL(string: self.redirectURI) else {
                print("Invalid redirect URI")
                return
            }

            // ✅ Now build the auth request
            let request = OIDAuthorizationRequest(configuration: config,
                                                  clientId: self.clientID,
                                                  clientSecret: nil,
                                                  scopes: [OIDScopeOpenID, OIDScopeProfile],
                                                  redirectURL: redirectURL,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: nil)

            // ✅ Start the authorization flow
            self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: presentingViewController) { authState, error in
                if let authState = authState {
                    self.authState = authState
                    print("Access token: \(authState.lastTokenResponse?.accessToken ?? "")")
                    self.fetchUserInfo()
                    // print("Authorization successful. Access token: \(authState.lastTokenResponse?.accessToken ?? "")")
                } else {
                    print("Authorization error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}
