//
//  MapCanvasView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/8/26.
//

import SwiftUI
import CoreLocation
import MapKit

struct MapCanvasView: View {
    @ObservedObject var controller: MapController

    @Binding var searchText: String
    @Binding var isSearchExpanded: Bool
    @FocusState.Binding var isSearchFocused: Bool

    let searchVM: SearchCompleterViewModel
    let selectedPlaceID: UUID?
    let userLocationManager: UserLocationManager

    let handleMarkerTap: (IdentifiablePlace) -> Void
    let handleMapTap: (CLLocationCoordinate2D) -> Void
    let handleRegionChange: (MKCoordinateRegion) -> Void

    @Namespace var animationNamespace

    var body: some View {
        ZStack(alignment: .topLeading) {

            MapDisplayView(
                region: $controller.region,
                markers: controller.markers,
                selectedPlaceID: selectedPlaceID,
                userLocationManager: userLocationManager,
                onMarkerTapped: handleMarkerTap,
                onMapTapped: handleMapTap,
                onRegionChange: handleRegionChange
            )
            .edgesIgnoringSafeArea(.horizontal)

            ScorecardBar()

            FloatingSearchAndMicButtons(
                searchText: $searchText,
                isExpanded: $isSearchExpanded,
                isFocused: $isSearchFocused,
                viewModel: searchVM,
                animationNamespace: animationNamespace,
                onSubmit: {},
                onSelectResult: { _ in },
                userLocationManager: userLocationManager,
                mapController: controller
            )

            if !isSearchExpanded {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        QRCodeCardView()
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}
