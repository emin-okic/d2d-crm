//
//  IdentifiablePlace.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/29/25.
//

import SwiftUI
import CoreLocation
import MapKit

/// A class representing a point of interest on the map, used for placing markers.
///
/// `IdentifiablePlace` is used to represent geocoded locations (addresses) on a map,
/// with a color-coded marker indicating how frequently the address has been knocked.
/// It conforms to `Identifiable` so it can be used in SwiftUI lists and `MapAnnotation`s.
class IdentifiablePlace: NSObject, Identifiable {
    
    /// Unique identifier for the marker.
    let id = UUID()
    
    /// The address associated with this place.
    let address: String
    
    /// The geographic coordinate of the place.
    let location: CLLocationCoordinate2D
    
    /// The number of times this address has been knocked.
    var count: Int

    /// A computed property returning a marker color based on `count`.
    ///
    /// - `0` knocks: Gray
    /// - `1` knock: Green
    /// - `2...4` knocks: Yellow
    /// - `5+` knocks: Red
    var markerColor: Color {
        switch count {
        case 0:
            return .gray
        case 1:
            return .green
        case 2...4:
            return .yellow
        default:
            return .red
        }
    }

    /// Initializes a new `IdentifiablePlace`.
    ///
    /// - Parameters:
    ///   - address: A string representing the human-readable address.
    ///   - location: The geographic coordinates of the place.
    ///   - count: Optional initial knock count (defaults to `1`).
    init(address: String, location: CLLocationCoordinate2D, count: Int = 1) {
        self.address = address
        self.location = location
        self.count = count
    }
}
