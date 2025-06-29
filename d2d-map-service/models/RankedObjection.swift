//
//  RankedObjection.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import Foundation
import SwiftData

struct RankedObjection: Identifiable {
    let id: PersistentIdentifier
    let rank: Int
    let objection: Objection

    init(rank: Int, objection: Objection) {
        self.rank = rank
        self.objection = objection
        self.id = objection.id
    }
}
