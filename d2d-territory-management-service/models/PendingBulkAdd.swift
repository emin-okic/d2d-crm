//
//  PendingBulkAdd.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/26/25.
//

import CoreLocation

struct PendingBulkAdd: Identifiable {
    let id = UUID()
    let center: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let properties: [PendingAddProperty]
}
