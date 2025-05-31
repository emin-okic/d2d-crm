//
//  IdentifiablePlace.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/29/25.
//

import SwiftUI
import CoreLocation
import MapKit

// This struct enables us to create "Identifiable Places"
// which is just making an easy to read coordinate map for
// the mapkit to use as markers and moving the map.

class IdentifiablePlace: NSObject, Identifiable {
    let id = UUID()
    let address: String
    let location: CLLocationCoordinate2D
    var count: Int

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

    init(address: String, location: CLLocationCoordinate2D, count: Int = 1) {
        self.address = address
        self.location = location
        self.count = count
    }
}
