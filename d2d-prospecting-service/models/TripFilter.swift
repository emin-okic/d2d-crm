//
//  TripFilter.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//


import SwiftUI
import SwiftData

enum TripFilter: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { self.rawValue }
}
