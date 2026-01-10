//
//  PopupWrapper.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/10/26.
//
import Foundation

struct PopupWrapper: Identifiable {
    let id = UUID()
    let address: String
    let contacts: [UnitContact]
}
