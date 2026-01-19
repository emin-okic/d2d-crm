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
        let targetID: PersistentIdentifier? = objection.persistentModelID

        let descriptor = FetchDescriptor<Recording>(
            predicate: #Predicate {
                $0.objection?.persistentModelID == targetID
            }
        )

        let recordings = (try? context.fetch(descriptor)) ?? []

        for rec in recordings {
            RecordingManager().delete(recording: rec, context: context)
        }

        context.delete(objection)
        try? context.save()
    }

    func recordingsCount(for objection: Objection, in context: ModelContext) -> Int {
        let targetID: PersistentIdentifier? = objection.persistentModelID

        let descriptor = FetchDescriptor<Recording>(
            predicate: #Predicate {
                $0.objection?.persistentModelID == targetID
            }
        )

        return (try? context.fetchCount(descriptor)) ?? 0
    }
}
