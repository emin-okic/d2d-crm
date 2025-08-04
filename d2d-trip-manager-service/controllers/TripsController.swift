//
//  TripsController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//
import Foundation
import MapKit

class TripsController {
    static let shared = TripsController()

    private init() {}

    func calculateMiles(from: String, to: String) async -> Double {
        let request = MKDirections.Request()
        request.transportType = .automobile

        let geocoder = CLGeocoder()
        do {
            let startPlacemarks = try await geocoder.geocodeAddressString(from)
            let endPlacemarks = try await geocoder.geocodeAddressString(to)

            guard let startPlacemark = startPlacemarks.first,
                  let endPlacemark = endPlacemarks.first else {
                print("❌ Missing placemarks")
                return 0.0
            }

            request.source = MKMapItem(placemark: MKPlacemark(placemark: startPlacemark))
            request.destination = MKMapItem(placemark: MKPlacemark(placemark: endPlacemark))

            let directions = MKDirections(request: request)
            let response = try await directions.calculate()

            if let route = response.routes.first {
                print("🧭 Route distance: \(route.distance / 1609.34) miles")
                return route.distance / 1609.34
            } else {
                print("❌ No route found")
                return 0.0
            }
        } catch {
            print("❌ Directions error: \(error.localizedDescription)")
            return 0.0
        }
    }
}
