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
    @State private var coordinate: CLLocationCoordinate2D?

    var body: some View {
        Map(
            coordinateRegion: $region,
            annotationItems: coordinate.map { [IdentifiableCoord(coord: $0)] } ?? []
        ) { item in
            MapAnnotation(coordinate: item.coord) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                    .shadow(radius: 2)
                    .offset(y: -12) // makes it feel like a dropped pin
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
                self.coordinate = coord
                self.region = MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
            }
        }
    }
}

private struct IdentifiableCoord: Identifiable {
    let id = UUID()
    let coord: CLLocationCoordinate2D
}
