//
//  IdentifiableAnnotation.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/20/25.
//

import MapKit

final class IdentifiableAnnotation: NSObject, MKAnnotation {
    let place: IdentifiablePlace

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
}
