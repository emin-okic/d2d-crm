//
//  MapSnapshotView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/13/25.
//
import SwiftUI
import MapKit

/// This class provides the UI for the snapshot needed in the new address popup view
/// This class is used in the AddPropertyConfirmationSheet
struct MapSnapshotView: View {
    let address: String

    @State private var position = MapCameraPosition.region(MKCoordinateRegion())
    @State private var place: IdentifiablePlace?

    var body: some View {
        Map(position: $position) {
            if let place {
                Annotation("", coordinate: place.location, anchor: .bottom) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                        .shadow(radius: 2)
                        .scaleEffect(1.1)
                        .transition(.scale.combined(with: .opacity))
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7),
                            value: place.id
                        )
                }
            }
        }
        .task(id: address) {
            await geocode()
        }
    }

    @MainActor
    private func geocode() async {
        guard let request = MKGeocodingRequest(addressString: address) else { return }

        do {
            guard let coord = try await request.mapItems.first?.location.coordinate else { return }

            place = IdentifiablePlace(
                address: address,
                location: coord,
                count: 0,
                list: "Preview"
            )

            position = .region(
                MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
            )
        } catch {
            return
        }
    }
}
