//
//  AddressGroup.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/9/26.
//

import Foundation
import CoreLocation

struct AddressGroup: Identifiable {
    let id = UUID()
    let baseAddress: String
    let coordinate: CLLocationCoordinate2D

    /// key: unit (nil = main), value: contacts at that unit
    let units: [String?: [UnitContact]]

    var unitCount: Int { units.keys.compactMap { $0 }.count }

    var totalContacts: Int {
        units.values.reduce(0) { $0 + $1.count }
    }

    var hasCustomer: Bool {
        units.values.flatMap { $0 }.contains { $0.isCustomer }
    }

    var hasUnqualified: Bool {
        units.values.flatMap { $0 }.contains { $0.isUnqualified }
    }

    var isMultiUnit: Bool { unitCount > 1 }
}
