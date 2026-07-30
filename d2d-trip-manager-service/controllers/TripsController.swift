//
//  TripsController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//
import Foundation
import MapKit

@MainActor
class TripsController {
    static let shared = TripsController()

    private init() {}

    // Existing single-leg function kept as-is...
    func calculateMiles(from: String, to: String) async -> Double {
        let request = MKDirections.Request()
        request.transportType = .automobile

        do {
            guard let startMapItem = try await mapItem(for: from),
                  let endMapItem = try await mapItem(for: to) else {
                print("❌ Missing map items")
                return 0.0
            }

            request.source = startMapItem
            request.destination = endMapItem

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

    /// Calculates total miles for a multi-leg route: start (optional) -> stops[0] -> stops[1] ...
    /// Uses routed distance (MKDirections) per leg and sums.
    func calculateMilesForRoute(for stops: [MKMapItem], start: MKMapItem?) async -> Double {
        guard !stops.isEmpty else { return 0.0 }

        var legs: [(MKMapItem, MKMapItem)] = []

        // If start supplied and different than first stop, start->first; else first->second ...
        if let startItem = start {
            legs.append((startItem, stops[0]))
            for i in 0..<(stops.count - 1) {
                legs.append((stops[i], stops[i + 1]))
            }
        } else {
            if stops.count >= 2 {
                for i in 0..<(stops.count - 1) {
                    legs.append((stops[i], stops[i + 1]))
                }
            }
        }

        var totalMeters: Double = 0
        for (src, dst) in legs {
            let req = MKDirections.Request()
            req.source = src
            req.destination = dst
            req.transportType = .automobile
            do {
                let resp = try await MKDirections(request: req).calculate()
                if let r = resp.routes.first { totalMeters += r.distance }
            } catch {
                // Fallback: straight-line if routing fails for a leg
                let startLocation: CLLocation
                let endLocation: CLLocation
                if #available(iOS 26.0, *) {
                    startLocation = src.location
                    endLocation = dst.location
                } else {
                    startLocation = src.placemark.location ?? CLLocation(latitude: src.placemark.coordinate.latitude, longitude: src.placemark.coordinate.longitude)
                    endLocation = dst.placemark.location ?? CLLocation(latitude: dst.placemark.coordinate.latitude, longitude: dst.placemark.coordinate.longitude)
                }
                totalMeters += startLocation.distance(from: endLocation)
            }
        }
        return totalMeters / 1609.34
    }

    private func mapItem(for address: String) async throws -> MKMapItem? {
        if #available(iOS 26.0, *) {
            guard let request = MKGeocodingRequest(addressString: address) else {
                return nil
            }
            return try await request.mapItems.first
        } else {
            let geocoder = CLGeocoder()
            return try await geocoder.geocodeAddressString(address).first.map {
                MKMapItem(placemark: MKPlacemark(placemark: $0))
            }
        }
    }
}
