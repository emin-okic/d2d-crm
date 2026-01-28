//
//  PhoneCallController.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/28/26.
//

import Foundation
import SwiftData
import PhoneNumberKit
import UIKit

@MainActor
final class PhoneCallController {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    func call(context: PhoneActionContext) {
        logCallNote(context: context)
        performCall(phone: context.getPhone())
    }

    // MARK: - Call + Logging

    private func performCall(phone: String) {
        let digits = phone.filter(\.isNumber)
        guard let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }

    private func logCallNote(context: PhoneActionContext) {

        let formatted = PhoneValidator.formatted(context.getPhone())
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)

        switch context.recipientType {

        case .prospect:
            guard let prospect = fetchProspect(id: context.id) else { return }

            let content = "Called prospect at \(formatted) on \(timestamp)."
            prospect.notes.append(Note(content: content, date: .now))
            try? modelContext.save()

        case .customer:
            guard let customer = fetchCustomer(id: context.id) else { return }

            let content = "Called customer at \(formatted) on \(timestamp)."
            customer.notes.append(Note(content: content, date: .now))
            try? modelContext.save()
        }
    }

    // MARK: - Fetch Helpers

    private func fetchProspect(id: UUID) -> Prospect? {
        let descriptor = FetchDescriptor<Prospect>(
            predicate: #Predicate { $0.uuid == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchCustomer(id: UUID) -> Customer? {
        let descriptor = FetchDescriptor<Customer>(
            predicate: #Predicate { $0.uuid == id }
        )
        return try? modelContext.fetch(descriptor).first
    }
}
