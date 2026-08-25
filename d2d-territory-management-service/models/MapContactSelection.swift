//
//  MapContactSelection.swift
//  d2d-studio
//
//  Created by Codex on 8/25/26.
//

import CoreLocation
import Foundation

struct MapContactSelection: Equatable {
    let contactID: UUID
    let address: String
    let list: String
    let coordinate: CLLocationCoordinate2D?

    static func == (lhs: MapContactSelection, rhs: MapContactSelection) -> Bool {
        lhs.contactID == rhs.contactID &&
        lhs.address == rhs.address &&
        lhs.list == rhs.list &&
        lhs.coordinate?.latitude == rhs.coordinate?.latitude &&
        lhs.coordinate?.longitude == rhs.coordinate?.longitude
    }
}
