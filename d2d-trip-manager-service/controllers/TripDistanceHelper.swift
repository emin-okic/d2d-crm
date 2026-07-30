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
        request.source = mapItem(for: start)
        request.destination = mapItem(for: end)
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

    private static func mapItem(for coordinate: CLLocationCoordinate2D) -> MKMapItem {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        if #available(iOS 26.0, *) {
            return MKMapItem(location: location, address: nil)
        } else {
            return MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        }
    }

    private static func geocode(address: String) async -> CLLocationCoordinate2D? {
        if #available(iOS 26.0, *) {
            guard let request = MKGeocodingRequest(addressString: address) else {
                return nil
            }

            do {
                return try await request.mapItems.first?.location.coordinate
            } catch {
                print("❌ Geocoding failed for \(address): \(error.localizedDescription)")
                return nil
            }
        } else {
            do {
                return try await CLGeocoder()
                    .geocodeAddressString(address)
                    .first?
                    .location?
                    .coordinate
            } catch {
                print("❌ Geocoding failed for \(address): \(error.localizedDescription)")
                return nil
            }
        }
    }
}
