//
//  UnitSelectorPopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI

struct UnitSelectorPopupView: View {
    let baseAddress: String
    let units: [UnitContactGroup]
    let onSelect: (UnitContactGroup) -> Void
    let onClose: () -> Void

    private var contactCount: Int {
        units.reduce(0) { $0 + $1.contactCount }
    }

    private var customerCount: Int {
        units.reduce(0) { total, group in
            total + group.contacts.filter(\.isCustomer).count
        }
    }

    private var unqualifiedCount: Int {
        units.reduce(0) { total, group in
            total + group.contacts.filter(\.isUnqualified).count
        }
    }

    private var prospectCount: Int {
        contactCount - customerCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summaryRow
            unitList
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.indigo.opacity(0.14))
                    .frame(width: 48, height: 48)

                Image(systemName: "building.2.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.indigo)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Multi-Unit Property")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.indigo)

                Text(baseAddress)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)

            Button(action: closePopup) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    private var summaryRow: some View {
            HStack(spacing: 8) {
                summaryTile(value: "\(units.count)", label: units.count == 1 ? "Unit" : "Units", systemName: "door.left.hand.open", tint: .indigo)
            summaryTile(value: "\(contactCount)", label: contactCount == 1 ? "Contact" : "Contacts", systemName: "person.2.fill", tint: .blue)
            summaryTile(value: "\(customerCount)", label: customerCount == 1 ? "Customer" : "Customers", systemName: "checkmark.seal.fill", tint: .green)
        }
    }

    private var unitList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Select Unit")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if unqualifiedCount > 0 {
                    Label("\(unqualifiedCount)", systemImage: "xmark.octagon.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(units) { unit in
                        Button {
                            select(unit)
                        } label: {
                            unitRow(for: unit)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func unitRow(for unit: UnitContactGroup) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor(for: unit).opacity(0.12))
                    .frame(width: 38, height: 38)

                Image(systemName: statusIcon(for: unit))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(statusColor(for: unit))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(unitLabel(for: unit))
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    if unit.contactCount > 1 {
                        Label("\(unit.contactCount)", systemImage: "person.2.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                    }

                    if unit.hasCustomer {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.yellow)
                            .padding(5)
                            .background(Color.yellow.opacity(0.14), in: Circle())
                    }
                }

                Text(unitSubtitle(for: unit))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            if unit.upcomingFollowUpCount > 0 {
                followUpLabel(count: unit.upcomingFollowUpCount)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func followUpLabel(count: Int) -> some View {
        Label("\(count)", systemImage: "calendar")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.12), in: Capsule())
            .accessibilityLabel("\(count) scheduled follow-ups")
    }

    private func summaryTile(value: String, label: String, systemName: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)

                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func select(_ unit: UnitContactGroup) {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()
        onSelect(unit)
    }

    private func closePopup() {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()
        onClose()
    }

    private func unitLabel(for unit: UnitContactGroup) -> String {
        if let unitNumber = unit.unit {
            return "Unit \(unitNumber)"
        }

        guard let contact = unit.primaryContact else { return "Main" }

        switch contact {
        case .prospect(let prospect):
            return prospect.fullName
        case .customer(let customer):
            return customer.fullName
        }
    }

    private func unitSubtitle(for unit: UnitContactGroup) -> String {
        let contactSummary = unit.contactCount == 1 ? "1 contact" : "\(unit.contactCount) contacts"
        let knockSummary = unit.knockCount == 1 ? "1 knock" : "\(unit.knockCount) knocks"

        guard unit.contactCount == 1, let contact = unit.primaryContact else {
            return "\(contactSummary) - \(knockSummary)"
        }

        let contactName: String
        switch contact {
        case .prospect(let prospect):
            contactName = prospect.fullName
        case .customer(let customer):
            contactName = customer.fullName
        }

        return "\(contactName) - \(knockSummary)"
    }

    private func statusIcon(for unit: UnitContactGroup) -> String {
        if unit.contactCount > 1 {
            return "person.2.fill"
        }

        if unit.hasCustomer {
            return "star.fill"
        }

        return unit.hasUnqualified ? "xmark.octagon.fill" : "person.crop.circle.badge.clock"
    }

    private func statusColor(for unit: UnitContactGroup) -> Color {
        if unit.hasCustomer {
            return .green
        }

        return unit.hasUnqualified ? .red : .blue
    }
}
