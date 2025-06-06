//
//  AuthManager.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/6/25.
//

import Foundation
import AppAuth

class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private var authState: OIDAuthState?

    private let issuer = URL(string: "https://cognito-idp.us-east-2.amazonaws.com/us-east-2_3qKzMckST")!
    private let clientID = "7hkvtmon35nr1qkjnscbvgsosk"
    private let redirectURI = URL(string: "com.yourapp.d2dcrm://oauth2redirect")!

    func signIn(presentingViewController: UIViewController, completion: @escaping (Bool, String?) -> Void) {
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { config, error in
            guard let config = config else {
                completion(false, "Discovery failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let request = OIDAuthorizationRequest(
                configuration: config,
                clientId: self.clientID,
                clientSecret: nil, // No secret
                scopes: [OIDScopeOpenID, OIDScopeProfile],
                redirectURL: self.redirectURI,
                responseType: OIDResponseTypeCode,
                additionalParameters: nil
            )

            self.currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: request,
                presenting: presentingViewController
            ) { authState, error in
                if let authState = authState {
                    self.authState = authState
                    completion(true, nil)
                } else {
                    completion(false, error?.localizedDescription ?? "Authorization failed")
                }
            }
        }
    }

    func resume(_ url: URL) -> Bool {
        return currentAuthorizationFlow?.resumeExternalUserAgentFlow(with: url) ?? false
    }
    
    func handleRedirectURL(_ url: URL) {
        if let currentAuthorizationFlow = currentAuthorizationFlow,
           currentAuthorizationFlow.resumeExternalUserAgentFlow(with: url) {
            self.currentAuthorizationFlow = nil
        }
    }
    
}
