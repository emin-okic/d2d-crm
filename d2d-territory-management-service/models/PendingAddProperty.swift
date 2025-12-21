//
//  PendingAddProperty.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/21/25.
//

import CoreLocation

struct PendingAddProperty: Identifiable {
    let id = UUID()
    let address: String
    let coordinate: CLLocationCoordinate2D
}
