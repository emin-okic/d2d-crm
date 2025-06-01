//
//  d2d_map_serviceApp.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/28/25.
//

import SwiftUI

@main
struct d2d_map_serviceApp: App {
    // @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            if session.isSignedIn {
                RootView()
                    .environmentObject(session)
            } else {
                LoginView()
                    .environmentObject(session)
            }
        }
    }
}
