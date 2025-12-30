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

    /// The model context environment for managing SwiftData operations.
    @Environment(\.modelContext) private var modelContext

    /// The region displayed on the map, initially centered on San Francisco.
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    /// The currently selected list filter (e.g., "Prospects" or "Customers").
    @State private var selectedList: String = "Prospects"

    /// Controls the presentation of the Add Prospect sheet (used in child view).
    @State private var showingAddProspect = false
    
    @State private var selectedTab = 0
    @State private var addressToCenter: String? = nil
    
    @State private var searchText: String = ""

    var body: some View {
        TabView {

            // 🗺 MAP
            Tab("Map", systemImage: "map.fill") {
                MapSearchView(
                    searchText: $searchText,
                    region: $region,
                    selectedList: $selectedList,
                    addressToCenter: $addressToCenter
                )
                .onAppear {
                    NotificationCenter.default.post(
                        name: .mapShouldRecenterAllMarkers,
                        object: nil
                    )
                }
            }

            // 👥 CONTACTS
            Tab("Contacts", systemImage: "person.3.fill") {
                ContactManagementView(
                    selectedList: $selectedList,
                    onSave: { showingAddProspect = false }
                )
            }

            // 📅 PIPELINE
            Tab("Pipeline", systemImage: "calendar") {
                FollowUpAssistantView()
            }
            // 🔍 SEARCH — SYSTEM ROLE
            Tab(role: .search) {
                SearchView()
            }
        }

        
    }
}

extension Notification.Name {
    static let mapShouldRecenterAllMarkers = Notification.Name("MapShouldRecenterAllMarkers")
}
