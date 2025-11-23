//
//  LocationManager.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/4/25.
//

import CoreLocation

/// A singleton class that manages the device's current geographic location.
///
/// `LocationManager` is used to request location permissions, start updating location,
/// and publish the latest coordinates for use throughout the app (e.g. logging knocks).
///

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    /// Shared instance used throughout the app.
    static let shared = LocationManager()

    /// The underlying Core Location manager.
    private let manager = CLLocationManager()

    /// The device's most recently determined geographic coordinates.
    @Published var currentLocation: CLLocationCoordinate2D?

    /// Private initializer to enforce singleton usage and configure the manager.
    private override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()  // Prompts user for location access
        manager.startUpdatingLocation()          // Begins location updates
    }

    /// CLLocationManagerDelegate callback that updates the published `currentLocation`.
    /// - Parameters:
    ///   - manager: The location manager providing updates.
    ///   - locations: Array of recent location updates.
    nonisolated(unsafe)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Hop back onto the main actor
        Task { @MainActor in
            self.currentLocation = locations.last?.coordinate
            
        }
        
    }
}
