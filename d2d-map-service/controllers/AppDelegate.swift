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
        print("👉 Received URL in AppDelegate: \(url.absoluteString)")

        if let currentFlow = AuthManager.shared.currentAuthorizationFlow,
           currentFlow.resumeExternalUserAgentFlow(with: url) {
            print("✅ Resumed external user agent flow")
            AuthManager.shared.currentAuthorizationFlow = nil
            return true
        }

        print("❌ Could not resume external user agent flow")
        return false
    }
}
