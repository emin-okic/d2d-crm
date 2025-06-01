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

    @State private var prospects: [Prospect] = []
    @State private var selectedList: String = "Prospects"
    @State private var showingAddProspect = false

    var body: some View {
        TabView {
            // 1) “Map” tab
            MapSearchView(
                region: $region,
                prospects: $prospects,
                selectedList: $selectedList
            )
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            // 2) “Prospects” tab
            ProspectsView(
                prospects: $prospects,
                selectedList: $selectedList
            ) {
                showingAddProspect = false
            }
            .tabItem {
                Label("Prospects", systemImage: "person.3.fill")
            }

            // 3) “Graph” tab — *now inside* the TabView
            GraphView(prospects: prospects)
                .tabItem {
                    Label("Graph", systemImage: "chart.bar.fill")
                }
        }
        .sheet(isPresented: $showingAddProspect) {
            NewProspectView(
                prospects: $prospects,
                selectedList: $selectedList
            ) {
                showingAddProspect = false
            }
        }
        .onAppear {
            // load from DB if needed
        }
    }
}
