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
    @State private var place: IdentifiablePlace?

    var body: some View {
        Map(
            coordinateRegion: $region,
            annotationItems: place.map { [$0] } ?? []
        ) { place in
            MapAnnotation(coordinate: place.location) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                    .shadow(radius: 2)
                    .offset(y: -12)
            }
        }
        .onAppear {
            geocode()
        }
    }

    private func geocode() {
        CLGeocoder().geocodeAddressString(address) { placemarks, _ in
            guard let coord = placemarks?.first?.location?.coordinate else { return }

            DispatchQueue.main.async {
                self.place = IdentifiablePlace(
                    address: address,
                    location: coord,
                    count: 0,
                    list: "Preview"
                )

                self.region = MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
            }
        }
    }
}
