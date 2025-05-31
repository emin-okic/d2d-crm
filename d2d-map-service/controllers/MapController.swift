//
//  MapController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation

struct MapController {
    static func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

