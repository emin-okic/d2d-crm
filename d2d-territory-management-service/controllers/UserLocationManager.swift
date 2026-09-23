//
//  UserLocationManager.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/20/25.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class UserLocationManager: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var pendingLocationContinuations: [CheckedContinuation<CLLocation?, Never>] = []

    @Published var heading: CLHeading?
    @Published var location: CLLocation?

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1

        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func currentLocation() async -> CLLocation? {
        if let location {
            return location
        }

        return await withCheckedContinuation { continuation in
            pendingLocationContinuations.append(continuation)

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .denied, .restricted:
                resumePendingLocationRequests(with: nil)
            @unknown default:
                resumePendingLocationRequests(with: nil)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latestLocation = locations.last else { return }
        location = latestLocation
        resumePendingLocationRequests(with: latestLocation)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            if !pendingLocationContinuations.isEmpty {
                manager.requestLocation()
            }
        case .denied, .restricted:
            resumePendingLocationRequests(with: nil)
        case .notDetermined:
            break
        @unknown default:
            resumePendingLocationRequests(with: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError, locationError.code == .locationUnknown {
            return
        }

        resumePendingLocationRequests(with: nil)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateHeading newHeading: CLHeading
    ) {
        heading = newHeading
    }

    func locationManagerShouldDisplayHeadingCalibration(
        _ manager: CLLocationManager
    ) -> Bool {
        true
    }

    private func resumePendingLocationRequests(with location: CLLocation?) {
        let continuations = pendingLocationContinuations
        pendingLocationContinuations.removeAll()
        continuations.forEach { $0.resume(returning: location) }
    }
}
