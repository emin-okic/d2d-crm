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
        logCall(context: context)
        performCall(phone: context.getPhone())
    }

    // MARK: - Call + Logging
    private func performCall(phone: String) {
        let digits = phone.filter(\.isNumber)
        guard let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }

    private func logCall(context: PhoneActionContext) {
        let formatted = PhoneValidator.formatted(context.getPhone())
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)

        switch context.recipientType {
        case .prospect:
            guard let prospect = fetchProspect(id: context.id) else { return }
            let note = Note(content: "Called prospect at \(formatted) on \(timestamp).", date: .now)
            prospect.notes.append(note)
            
            // ✅ Track phone call object
            let call = PhoneCall(date: .now, recipientUUID: prospect.uuid, recipientType: .prospect)
            prospect.phoneCalls.append(call)
            
            try? modelContext.save()

        case .customer:
            guard let customer = fetchCustomer(id: context.id) else { return }
            let note = Note(content: "Called customer at \(formatted) on \(timestamp).", date: .now)
            customer.notes.append(note)
            
            // ✅ Track phone call object
            let call = PhoneCall(date: .now, recipientUUID: customer.uuid, recipientType: .customer)
            customer.phoneCalls.append(call)
            
            try? modelContext.save()
        }
    }

    // MARK: - Total Calls
    func totalCallsMade(for context: PhoneActionContext) -> Int {
        switch context.recipientType {
        case .prospect:
            guard let prospect = fetchProspect(id: context.id) else { return 0 }
            return prospect.phoneCalls.count
        case .customer:
            guard let customer = fetchCustomer(id: context.id) else { return 0 }
            return customer.phoneCalls.count
        }
    }

    // MARK: - Fetch Helpers
    private func fetchProspect(id: UUID) -> Prospect? {
        let descriptor = FetchDescriptor<Prospect>(predicate: #Predicate { $0.uuid == id })
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchCustomer(id: UUID) -> Customer? {
        let descriptor = FetchDescriptor<Customer>(predicate: #Predicate { $0.uuid == id })
        return try? modelContext.fetch(descriptor).first
    }
}
