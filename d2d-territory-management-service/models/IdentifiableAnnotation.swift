//
//  IdentifiableAnnotation.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/20/25.
//

import MapKit

final class IdentifiableAnnotation: NSObject, MKAnnotation {
    private(set) var place: IdentifiablePlace

    var coordinate: CLLocationCoordinate2D {
        place.location
    }

    var title: String? {
        place.address
    }

    init(place: IdentifiablePlace) {
        self.place = place
        super.init()
    }

    @discardableResult
    func update(with updatedPlace: IdentifiablePlace) -> Bool {
        let coordinateChanged = coordinate.latitude != updatedPlace.location.latitude ||
            coordinate.longitude != updatedPlace.location.longitude
        let appearanceChanged = coordinateChanged ||
            place.count != updatedPlace.count ||
            place.unitCount != updatedPlace.unitCount ||
            place.contactCount != updatedPlace.contactCount ||
            place.list != updatedPlace.list ||
            place.isUnqualified != updatedPlace.isUnqualified ||
            place.isMultiUnit != updatedPlace.isMultiUnit ||
            place.showsMultiContact != updatedPlace.showsMultiContact

        if coordinateChanged {
            willChangeValue(forKey: #keyPath(coordinate))
        }

        place = updatedPlace

        if coordinateChanged {
            didChangeValue(forKey: #keyPath(coordinate))
        }

        return appearanceChanged
    }
}
