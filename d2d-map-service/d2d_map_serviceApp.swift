//
//  d2d_map_serviceApp.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/28/25.
//

import SwiftUI
import AppAuth

@main
struct d2d_map_serviceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @AppStorage("isLoggedIn") var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                RootView()
            } else {
                LoginView()
            }
        }
    }
}
