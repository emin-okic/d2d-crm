//
//  UnitSelectorPopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI

struct UnitSelectorPopupView: View {
    let baseAddress: String
    let units: [UnitContact]
    let onSelect: (UnitContact) -> Void
    let onClose: () -> Void

    private var customerCount: Int {
        units.filter(\.isCustomer).count
    }

    private var unqualifiedCount: Int {
        units.filter(\.isUnqualified).count
    }

    private var prospectCount: Int {
        units.count - customerCount
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
            summaryTile(value: "\(prospectCount)", label: prospectCount == 1 ? "Prospect" : "Prospects", systemName: "person.crop.circle.badge.clock", tint: .blue)
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

    private func unitRow(for unit: UnitContact) -> some View {
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

                    Text(statusLabel(for: unit))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(statusColor(for: unit))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(statusColor(for: unit).opacity(0.1), in: Capsule())
                }

                Text(unitSubtitle(for: unit))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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

    private func select(_ unit: UnitContact) {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()
        onSelect(unit)
    }

    private func closePopup() {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()
        onClose()
    }

    private func unitLabel(for unit: UnitContact) -> String {
        if let unitNumber = parseAddress(unit.address).unit {
            return "Unit \(unitNumber)"
        }

        switch unit {
        case .prospect(let prospect):
            return prospect.fullName
        case .customer(let customer):
            return customer.fullName
        }
    }

    private func unitSubtitle(for unit: UnitContact) -> String {
        let contactName: String

        switch unit {
        case .prospect(let prospect):
            contactName = prospect.fullName
        case .customer(let customer):
            contactName = customer.fullName
        }

        let knocks = unit.knockCount == 1 ? "1 knock" : "\(unit.knockCount) knocks"
        return "\(contactName) - \(knocks)"
    }

    private func statusIcon(for unit: UnitContact) -> String {
        if unit.isCustomer {
            return "checkmark.seal.fill"
        }

        return unit.isUnqualified ? "xmark.octagon.fill" : "person.crop.circle.badge.clock"
    }

    private func statusLabel(for unit: UnitContact) -> String {
        if unit.isCustomer {
            return "Customer"
        }

        return unit.isUnqualified ? "Unqualified" : "Prospect"
    }

    private func statusColor(for unit: UnitContact) -> Color {
        if unit.isCustomer {
            return .green
        }

        return unit.isUnqualified ? .red : .blue
    }
}
