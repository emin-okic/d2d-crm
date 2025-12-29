//
//  AppointmentFilter.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/31/25.
//
import SwiftUI
import SwiftData

enum AppointmentFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case upcoming = "Upcoming"
    case past = "Past"

    var id: String { self.rawValue }
}
