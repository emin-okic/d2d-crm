//
//  IdentifiablePlace.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/29/25.
//

import SwiftUI
import CoreLocation
import MapKit

/// A struct representing a point of interest on the map, used for placing markers.
///
/// `IdentifiablePlace` is used to represent geocoded locations (addresses) on a map,
/// with a color-coded marker indicating how frequently the address has been knocked.
/// It conforms to `Identifiable` so it can be used in SwiftUI lists and `MapAnnotation`s.
struct IdentifiablePlace: Identifiable {
    
    /// Unique identifier for the marker.
    let id = UUID()
    
    /// The address associated with this place.
    let address: String
    
    /// The geographic coordinate of the place.
    let location: CLLocationCoordinate2D
    
    /// The number of times this address has been knocked.
    var count: Int
    
    /// Number of distinct units at this location
    var unitCount: Int

    /// The type of list the place belongs to ("Prospects" or "Customers").
    let list: String

    /// A computed property returning a marker color based on `count`.
    ///
    /// - `0` knocks: Gray
    /// - `1` knock: Green
    /// - `2...4` knocks: Yellow
    /// - `5+` knocks: Red
    var markerColor: Color {
        
        // Override everything if unqualified
        if isUnqualified { return .red }
        
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
    
    let isUnqualified: Bool
    
    let isMultiUnit: Bool
    
    let showsMultiContact: Bool

    /// Initializes a new `IdentifiablePlace`.
    ///
    /// - Parameters:
    ///   - address: A string representing the human-readable address.
    ///   - location: The geographic coordinates of the place.
    ///   - count: Optional initial knock count (defaults to `1`).
    ///   - list: The category of this place (e.g., "Customers", "Prospects").
    init(
        address: String,
        location: CLLocationCoordinate2D,
        count: Int = 1,
        unitCount: Int = 1,
        list: String = "Prospects",
        isUnqualified: Bool = false,
        isMultiUnit: Bool = false,
        showsMultiContact: Bool = false   // 👈 add
    ) {
        self.address = address
        self.location = location
        self.count = count
        self.unitCount = unitCount
        self.list = list
        self.isUnqualified = isUnqualified
        self.isMultiUnit = isMultiUnit
        self.showsMultiContact = showsMultiContact
    }
}
