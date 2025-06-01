//
//  AuthManager.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/1/25.
//

import Foundation
import AppAuth

class AuthManager {
    
    static let shared = AuthManager()

    // OIDC Configuration
    let issuer: String = "https://cognito-idp.us-east-2.amazonaws.com/us-east-2_3qKzMckST"
    let clientID: String = "7hkvtmon35nr1qkjnscbvgsosk"
    let redirectURI: String = "https://d84l1y8p4kdic.cloudfront.net"
    let logoutURL: String = "myapp://logout"
    
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    var authState: OIDAuthState?

    private init() {}

    func authorize(presentingViewController: UIViewController, completion: @escaping (Result<OIDAuthState, Error>) -> Void) {
        guard let issuerURL = URL(string: issuer) else {
            completion(.failure(NSError(domain: "InvalidIssuer", code: -1, userInfo: nil)))
            return
        }

        OIDAuthorizationService.discoverConfiguration(forIssuer: issuerURL) { configuration, error in
            guard let config = configuration else {
                completion(.failure(error!))
                return
            }

            guard let redirectURI = URL(string: self.redirectURI) else {
                completion(.failure(NSError(domain: "InvalidRedirectURI", code: -1, userInfo: nil)))
                return
            }

            let request = OIDAuthorizationRequest(configuration: config,
                                                  clientId: self.clientID,
                                                  clientSecret: nil,
                                                  scopes: [OIDScopeOpenID, OIDScopeProfile],
                                                  redirectURL: redirectURI,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: nil)

            self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: presentingViewController) { authState, error in
                if let authState = authState {
                    self.authState = authState
                    completion(.success(authState))
                } else {
                    completion(.failure(error!))
                }
            }
        }
    }
}
