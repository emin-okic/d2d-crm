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
        center: CLLocationCoordinate2D(latitude: 37.7749,
                                       longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1,
                               longitudeDelta: 0.1)
    )
    
    @State private var prospects: [Prospect] = []
    
    // Lifted state: only one `selectedList` here
    @State private var selectedList: String = "Prospects"
    
    @State private var showingAddProspect = false

    var body: some View {
        TabView {
            // Pass the same `$selectedList` to MapSearchView
            MapSearchView(
                region: $region,
                prospects: $prospects,
                selectedList: $selectedList
            )
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            // Pass the same `$selectedList` to ProspectsView
            ProspectsView(
                prospects: $prospects,
                selectedList: $selectedList,
                onSave: {
                    // If you save via a sheet or some button, you might reload from DB here.
                    showingAddProspect = false
                }
            )
            .tabItem {
                Label("Prospects", systemImage: "person.3.fill")
            }
        }
        // Present the “Add Prospect” sheet if requested
        .sheet(isPresented: $showingAddProspect) {
            NewProspectView(
                prospects: $prospects,
                selectedList: $selectedList
            ) {
                showingAddProspect = false
            }
        }
        .onAppear {
            // If you want to load from SQLite initially:
            // prospects = DatabaseController.shared.getAllProspects(for: selectedList)
        }
    }
}
