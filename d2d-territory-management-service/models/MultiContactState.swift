//
//  MultiContactState.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/10/26.
//
import Foundation

// MARK: - MultiContactState wrapper
struct MultiContactState: Identifiable {
    let id = UUID()
    let address: String
    let contacts: [UnitContact]
}
