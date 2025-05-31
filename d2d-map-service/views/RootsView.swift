//
//  RootsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/29/25.
//

import SwiftUI
import MapKit

struct RootView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var prospects: [Prospect] = []  // 👈 Shared state
    
    // Create the store instance here, assuming ProspectsStore is a class or struct you can instantiate
    @StateObject private var listStore = ProspectListStore()

    var body: some View {
        TabView {
            MapSearchView(region: $region, prospects: $prospects, listStore: listStore)
                .tabItem { Label("Map", systemImage: "map.fill") }


            ProspectsView(prospects: $prospects)
                .tabItem {
                    Label("Prospects", systemImage: "person.3.fill")
                }
        }
    }
}
