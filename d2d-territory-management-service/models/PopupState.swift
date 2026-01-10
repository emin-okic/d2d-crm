//
//  PopupState.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/9/26.
//

import Foundation

struct PopupState: Identifiable, Equatable {
    let id = UUID()
    let place: IdentifiablePlace
    static func == (lhs: PopupState, rhs: PopupState) -> Bool { lhs.id == rhs.id }
}
