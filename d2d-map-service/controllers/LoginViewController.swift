//
//  LoginViewController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/1/25.
//
import UIKit
import AppAuth

class LoginViewController: UIViewController {

    private var authState: OIDAuthState?

    private let issuer = URL(string: "https://cognito-idp.us-east-2.amazonaws.com/us-east-2_3qKzMckST")!
    private let clientID = "7hkvtmon35nr1qkjnscbvgsosk"
    private let redirectURI = URL(string: "myapp://callback")!
    private let logoutURL = URL(string: "myapp://logout")!

    override func viewDidLoad() {
        super.viewDidLoad()
        login()
    }

    func login() {
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { config, error in
            guard let config = config else {
                print("Discovery failed: \(error?.localizedDescription ?? "No error info")")
                return
            }

            let request = OIDAuthorizationRequest(
                configuration: config,
                clientId: self.clientID,
                scopes: [OIDScopeOpenID, OIDScopeProfile, "email"],
                redirectURL: self.redirectURI,
                responseType: OIDResponseTypeCode,
                additionalParameters: nil
            )

            self.authState = nil  // Reset

            guard let presentingVC = UIApplication.shared.windows.first?.rootViewController else {
                print("Missing presenting VC")
                return
            }

            let appDelegate = UIApplication.shared.delegate as! AppDelegate

            appDelegate.currentAuthorizationFlow =
                OIDAuthState.authState(byPresenting: request, presenting: presentingVC) { authState, error in
                    if let authState = authState {
                        self.authState = authState
                        print("Logged in! Access token: \(authState.lastTokenResponse?.accessToken ?? "none")")
                    } else {
                        print("Login failed: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
        }
    }
    
    func logout() {
        guard let config = authState?.lastAuthorizationResponse.request.configuration,
              let endSessionEndpoint = config.discoveryDocument?.endSessionEndpoint else {
            return
        }

        var components = URLComponents(url: endSessionEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "logout_uri", value: logoutURL.absoluteString)
        ]

        if let logoutURL = components.url {
            UIApplication.shared.open(logoutURL, options: [:], completionHandler: nil)
        }
    }
}
