//
//  Knock.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation

struct Knock: Identifiable, Equatable, Hashable {
    let id = UUID()
    var date: Date
    var status: String
    var latitude: Double
    var longitude: Double
}
