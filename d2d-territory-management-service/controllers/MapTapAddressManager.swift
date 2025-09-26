//
//  MapTapAddressManager.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/11/25.
//
import Foundation
import MapKit
import CoreLocation

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
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let placemark = placemarks?.first {
                let addr = [placemark.subThoroughfare,
                            placemark.thoroughfare,
                            placemark.locality].compactMap { $0 }.joined(separator: " ")
                DispatchQueue.main.async {
                    self.tappedAddress = addr
                    self.showAddPrompt = true
                }
            }
        }
    }
}
