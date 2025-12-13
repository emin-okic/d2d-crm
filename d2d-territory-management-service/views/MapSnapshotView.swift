//
//  MapSnapshotView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/13/25.
//
import SwiftUI
import MapKit
import CoreLocation
import SwiftData
import Combine
import Contacts

struct MapSnapshotView: View {
    let address: String
    @State private var region = MKCoordinateRegion()

    var body: some View {
        Map(coordinateRegion: $region)
            .onAppear {
                CLGeocoder().geocodeAddressString(address) { placemarks, _ in
                    if let coord = placemarks?.first?.location?.coordinate {
                        region = MKCoordinateRegion(
                            center: coord,
                            latitudinalMeters: 500,
                            longitudinalMeters: 500
                        )
                    }
                }
            }
    }
}
