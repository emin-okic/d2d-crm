//
//  MapContactNavigationRequest.swift
//  d2d-studio
//
//  Created by Codex on 8/24/26.
//

import Foundation

enum MapContactNavigationType: String, Equatable {
    case prospect
    case customer

    var listName: String {
        switch self {
        case .prospect:
            return "Prospects"
        case .customer:
            return "Customers"
        }
    }
}

struct MapContactNavigationRequest: Equatable {
    let contactID: UUID
    let type: MapContactNavigationType
    let address: String
}
