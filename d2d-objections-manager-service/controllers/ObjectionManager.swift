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
        delete([objection], from: context)
    }

    func delete(_ objections: [Objection], from context: ModelContext) {
        guard !objections.isEmpty else { return }

        let objectionIDs = Set(objections.map(\.persistentModelID))
        let recordings = (try? context.fetch(FetchDescriptor<Recording>())) ?? []
        let recordingManager = RecordingManager()

        for recording in recordings where recording.objection.map({ objectionIDs.contains($0.persistentModelID) }) == true {
            recordingManager.delete(recording: recording, context: context)
        }

        for objection in objections {
            context.delete(objection)
        }

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
