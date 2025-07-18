//
//  MapDisplayView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//
import SwiftUI
import MapKit
import CoreLocation
import SwiftData
import Combine
import Contacts

struct MapDisplayView: View {
    @Binding var region: MKCoordinateRegion
    var markers: [IdentifiablePlace]
    var onMarkerTapped: (IdentifiablePlace) -> Void
    var onMapTapped: () -> Void

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: markers) { place in
            MapAnnotation(coordinate: place.location) {
                MarkerView(place: place)
                    .onTapGesture {
                        onMarkerTapped(place)
                    }
            }
        }
        .gesture(TapGesture().onEnded { onMapTapped() })
    }
}
