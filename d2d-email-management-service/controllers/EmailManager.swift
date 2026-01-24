//
//  EmailManager.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/24/26.
//

import Foundation
import SwiftData


@MainActor
final class EmailManager {

    let context: EmailContactContext
    let modelContext: ModelContext

    init(context: EmailContactContext, modelContext: ModelContext) {
        self.context = context
        self.modelContext = modelContext
    }

    func send(template: EmailTemplate) {
        let body = template.body
            .replacingOccurrences(of: "{{name}}", with: context.displayName)

        EmailComposer.compose(
            to: context.getEmail(),
            subject: template.subject,
            body: body
        )

        logEmailNote()
    }

    func sendBlank() {
        EmailComposer.compose(
            to: context.getEmail(),
            subject: "",
            body: ""
        )
        logEmailNote()
    }

    private func logEmailNote() {
        let note = Note(
            content: "Sent email to \(context.getEmail()) on \(Date().formatted(date: .abbreviated, time: .shortened)).",
            date: Date()
        )

        context.appendNote(note)
        try? modelContext.save()
    }
}
