//
//  MultiContactState.swift
//  d2d-studio
//

import Foundation

struct MultiContactState: Identifiable {
    let id = UUID()
    let baseAddress: String
    let unit: String?
    let contacts: [UnitContact]
}
