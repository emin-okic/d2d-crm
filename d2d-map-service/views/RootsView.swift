//
//  RootsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/29/25.
//

import SwiftUI
import SwiftData
import MapKit

struct RootView: View {
    @Binding var isLoggedIn: Bool
    
    @Environment(\.modelContext) private var modelContext

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    @State private var selectedList: String = "Prospects"
    @State private var showingAddProspect = false

    var body: some View {
        TabView {
            MapSearchView(
                region: $region,
                selectedList: $selectedList
            )
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            ProspectsView(
                selectedList: $selectedList
            ) {
                showingAddProspect = false
            }
            .tabItem {
                Label("Prospects", systemImage: "person.3.fill")
            }

            ProfileView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}
