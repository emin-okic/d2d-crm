//
//  RootsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/29/25.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            ProspectsView()
                .tabItem {
                    Label("Prospects", systemImage: "person.3.fill")
                }
        }
    }
}
