//
//  MapTapAddressManager.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/11/25.
//
import Foundation
import MapKit
import CoreLocation

@MainActor
class MapTapAddressManager: ObservableObject {
    
    @Published var tappedAddress: String = ""
    @Published var tappedCoordinate: CLLocationCoordinate2D?
    
    @Published var showAddPrompt: Bool = false

    func handleTap(at coordinate: CLLocationCoordinate2D) {
        
        tappedCoordinate = coordinate
        reverseGeocode(coordinate)
        
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        Task { [weak self] in
            guard let request = MKReverseGeocodingRequest(location: location),
                  let mapItem = try? await request.mapItems.first,
                  let address = mapItem.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true)
                    ?? mapItem.address?.fullAddress.replacingOccurrences(of: "\n", with: ", ")
                    ?? mapItem.name else {
                return
            }

            await MainActor.run {
                self?.tappedAddress = address
                self?.showAddPrompt = true
            }
        }
    }
}
