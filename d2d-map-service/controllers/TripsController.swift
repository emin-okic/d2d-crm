//
//  TripsController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//
import Foundation
import CoreLocation

class TripsController {
    static let shared = TripsController()

    private init() {}

    func calculateMiles(from: String, to: String) async -> Double {
        let geocoder = CLGeocoder()

        do {
            let startResults = try await geocoder.geocodeAddressString(from)
            let endResults = try await geocoder.geocodeAddressString(to)

            guard let start = startResults.first?.location?.coordinate,
                  let end = endResults.first?.location?.coordinate else {
                print("❌ Coordinates not found for given addresses")
                return 0.0
            }

            let startLoc = CLLocation(latitude: start.latitude, longitude: start.longitude)
            let endLoc = CLLocation(latitude: end.latitude, longitude: end.longitude)
            let meters = startLoc.distance(from: endLoc)
            return meters / 1609.34
        } catch {
            print("❌ Geocoding failed: \(error.localizedDescription)")
            return 0.0
        }
    }
}
