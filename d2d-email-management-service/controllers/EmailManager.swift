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
        let renderedBody = template.body
            .replacingOccurrences(of: "{{name}}", with: context.displayName)

        EmailComposer.compose(
            to: context.getEmail(),
            subject: template.subject,
            body: renderedBody
        )

        logEmail(
            subject: template.subject,
            body: renderedBody,
            template: template
        )
    }
    
    private func logEmail(
        subject: String,
        body: String,
        template: EmailTemplate?
    ) {
        let email = Email(
            recipientUUID: context.id,
            recipientType: context.recipientType,
            templateUUID: template?.id,
            subject: subject,
            body: body
        )

        modelContext.insert(email)

        // Append email to the recipient's emailsSent array
        switch context.recipientType {
        case .prospect:
            let idToFind = context.id
            let fetch = FetchDescriptor<Prospect>(predicate: #Predicate { $0.uuid == idToFind })
            if let prospect = try? modelContext.fetch(fetch).first {
                prospect.emailsSent.append(email)
            }

        case .customer:
            let idToFind = context.id
            let fetch = FetchDescriptor<Customer>(predicate: #Predicate { $0.uuid == idToFind })
            if let customer = try? modelContext.fetch(fetch).first {
                customer.emailsSent.append(email)
            }
        }

        // Add a note about the email
        let note = Note(
            content: "Sent email: “\(subject)” on \(Date().formatted(date: .abbreviated, time: .shortened)).",
            date: Date()
        )
        context.appendNote(note)

        try? modelContext.save()
    }

    func sendBlank() {
        EmailComposer.compose(
            to: context.getEmail(),
            subject: "",
            body: ""
        )

        logEmail(subject: "", body: "", template: nil)
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
