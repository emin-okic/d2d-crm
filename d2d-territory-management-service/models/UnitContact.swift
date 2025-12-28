//
//  UnitContact.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//
import Foundation
import CoreLocation

enum UnitContact: Identifiable {
    case prospect(Prospect)
    case customer(Customer)

    var id: AnyHashable {
        switch self {
        case .prospect(let p):
            return p.persistentModelID
        case .customer(let c):
            return c.persistentModelID
        }
    }

    var address: String {
        switch self {
        case .prospect(let p): return p.address
        case .customer(let c): return c.address
        }
    }
    
    var isUnqualified: Bool {
        switch self {
        case .prospect(let p):
            return p.isUnqualified
        case .customer:
            return false
        }
    }

    var isCustomer: Bool {
        if case .customer = self { return true }
        return false
    }

    var coordinate: CLLocationCoordinate2D? {
        switch self {
        case .prospect(let p): return p.coordinate
        case .customer(let c): return c.coordinate
        }
    }

    var knockCount: Int {
        switch self {
        case .prospect(let p): return p.knockHistory.count
        case .customer(let c): return c.knockHistory.count
        }
    }

    var list: String {
        isCustomer ? "Customers" : "Prospects"
    }
}
