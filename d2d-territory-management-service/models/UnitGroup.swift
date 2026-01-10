//
//  UnitGroup.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//
import Foundation

struct UnitGroup: Identifiable {
    let id = UUID()
    let base: String
    let units: [String?: [UnitContact]]   // unit → contacts
}
