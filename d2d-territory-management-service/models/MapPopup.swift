//
//  MapPopup.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/9/26.
//

enum MapPopup: Identifiable {
    case prospect(place: IdentifiablePlace)
    case unitSelector(group: AddressGroup)
    case multiContact(address: String, contacts: [UnitContact])

    var id: String {
        switch self {
        case .prospect(let place):
            return "prospect-\(place.id)"
        case .unitSelector(let group):
            return "units-\(group.id)"
        case .multiContact(let address, _):
            return "multi-\(address)"
        }
    }
}
