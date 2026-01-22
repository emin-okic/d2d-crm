//
//  EmailTemplatesController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/21/26.
//

import SwiftUI
import SwiftData

@MainActor
final class EmailTemplatesController: ObservableObject {
    let modelContext: ModelContext
    let prospect: Prospect

    init(modelContext: ModelContext, prospect: Prospect) {
        self.modelContext = modelContext
        self.prospect = prospect
    }

    func compose(template: EmailTemplate) {
        let personalizedBody = template.body
            .replacingOccurrences(of: "{{name}}", with: prospect.fullName)

        EmailComposer.compose(
            to: prospect.contactEmail,
            subject: template.subject,
            body: personalizedBody
        )
    }
    
    func composeBlankEmail() {
        EmailComposer.compose(
            to: prospect.contactEmail,
            subject: "",
            body: ""
        )
    }
}
