//
//  AppDelegate.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/1/25.
//

import AppAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let currentFlow = AuthManager.shared.currentAuthorizationFlow,
           currentFlow.resumeExternalUserAgentFlow(with: url) {
            AuthManager.shared.currentAuthorizationFlow = nil
            return true
        }
        return false
    }
}
