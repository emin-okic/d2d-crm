//
//  ObjectionManager.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import SwiftUI
import SwiftData

class ObjectionManager {
    func delete(_ objection: Objection, from context: ModelContext) {
        context.delete(objection)
    }
}
