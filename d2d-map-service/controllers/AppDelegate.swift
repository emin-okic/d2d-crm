//
//  AppDelegate.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/1/25.
//

import UIKit
import AppAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let flow = currentAuthorizationFlow,
           flow.resumeExternalUserAgentFlow(with: url) {
            currentAuthorizationFlow = nil
            return true
        }
        return false
    }
}
