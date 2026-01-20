//
//  PopupState.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/19/26.
//

import Foundation

final class PopupState: Identifiable, Equatable, ObservableObject {
    let id = UUID()
    let place: IdentifiablePlace

    init(place: IdentifiablePlace) {
        self.place = place
    }

    static func == (lhs: PopupState, rhs: PopupState) -> Bool {
        lhs.id == rhs.id
    }
}
