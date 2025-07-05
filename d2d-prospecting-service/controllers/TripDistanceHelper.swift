//
//  TripDistanceHelper.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import Foundation
import MapKit

enum TripDistanceHelper {
    static func calculateMiles(from startAddress: String, to endAddress: String) async -> Double {
        let startCoordinate = await geocode(address: startAddress)
        let endCoordinate = await geocode(address: endAddress)

        guard let start = startCoordinate, let end = endCoordinate else {
            return 0.0
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .automobile

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            if let route = response.routes.first {
                let meters = route.distance
                return meters / 1609.34 // convert meters to miles
            }
        } catch {
            print("❌ Error calculating route: \(error)")
        }

        return 0.0
    }

    private static func geocode(address: String) async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            CLGeocoder().geocodeAddressString(address) { placemarks, error in
                if let coordinate = placemarks?.first?.location?.coordinate {
                    continuation.resume(returning: coordinate)
                } else {
                    print("❌ Geocoding failed for \(address): \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
