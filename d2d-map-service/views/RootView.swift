//
//  RootView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/29/25.
//

import SwiftUI
import SwiftData
import MapKit

/// The main root view for the app, responsible for coordinating top-level navigation
/// between the map, prospect list, and user profile screens.
///
/// This view is only shown after a user logs in, and it passes the user's email to
/// all child views to filter data appropriately.
struct RootView: View {
    /// Tracks the logged-in state of the user. If set to `false`, the app shows the login screen again.
    @Binding var isLoggedIn: Bool

    /// The logged-in user's email, used for filtering user-specific data.
    let userEmail: String

    /// The model context environment for managing SwiftData operations.
    @Environment(\.modelContext) private var modelContext

    /// The region displayed on the map, initially centered on San Francisco.
    @State private var region: MKCoordinateRegion? = nil

    /// The currently selected list filter (e.g., "Prospects" or "Customers").
    @State private var selectedList: String = "Prospects"

    /// Controls the presentation of the Add Prospect sheet (used in child view).
    @State private var showingAddProspect = false

    var body: some View {
        if let region = region {
            TabView {
                MapSearchView(
                    region: Binding(get: { region }, set: { self.region = $0 }),
                    selectedList: $selectedList,
                    userEmail: userEmail
                )
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

                ProspectsView(
                    selectedList: $selectedList,
                    userEmail: userEmail
                ) {
                    showingAddProspect = false
                }
                .tabItem {
                    Label("Prospects", systemImage: "person.3.fill")
                }

                ProfileView(
                    isLoggedIn: $isLoggedIn,
                    userEmail: userEmail
                )
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            }
        } else {
            ProgressView("Loading your location...")
                .onAppear {
                    if let loc = LocationManager.shared.currentLocation {
                        region = MKCoordinateRegion(
                            center: loc,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    } else {
                        // fallback if user denies location
                        region = MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 41.5868, longitude: -93.6250), // Des Moines
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        )
                    }
                }
        }
        
    }
}
