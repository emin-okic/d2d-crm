//
//  MultiContactPopupView.swift
//  d2d-studio
//

import SwiftUI

struct MultiContactPopupView: View {
    let state: MultiContactState
    let onSelect: (UnitContact) -> Void
    let onClose: () -> Void

    private var customerCount: Int {
        state.contacts.filter(\.isCustomer).count
    }

    private var prospectCount: Int {
        state.contacts.count - customerCount
    }

    private var title: String {
        if let unit = state.unit {
            return "Unit \(unit)"
        }

        return "Multiple Contacts"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summaryRow
            contactList
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
                    .fill(Color.blue.opacity(0.14))
                    .frame(width: 48, height: 48)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)

                Text(state.baseAddress)
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
            summaryTile(value: "\(state.contacts.count)", label: state.contacts.count == 1 ? "Contact" : "Contacts", systemName: "person.2.fill", tint: .blue)
            summaryTile(value: "\(prospectCount)", label: prospectCount == 1 ? "Prospect" : "Prospects", systemName: "person.crop.circle.badge.clock", tint: .indigo)
            summaryTile(value: "\(customerCount)", label: customerCount == 1 ? "Customer" : "Customers", systemName: "star.fill", tint: .yellow)
        }
    }

    private var contactList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Contact")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(state.contacts) { contact in
                        Button {
                            select(contact)
                        } label: {
                            contactRow(for: contact)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func contactRow(for contact: UnitContact) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor(for: contact).opacity(0.12))
                    .frame(width: 38, height: 38)

                Image(systemName: statusIcon(for: contact))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(statusColor(for: contact))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(contactName(for: contact))
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    if contact.isCustomer {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.yellow)
                            .padding(5)
                            .background(Color.yellow.opacity(0.14), in: Circle())
                    }
                }

                Text(contactSubtitle(for: contact))
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

    private func select(_ contact: UnitContact) {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()
        onSelect(contact)
    }

    private func closePopup() {
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()
        onClose()
    }

    private func contactName(for contact: UnitContact) -> String {
        switch contact {
        case .prospect(let prospect):
            return prospect.fullName
        case .customer(let customer):
            return customer.fullName
        }
    }

    private func contactSubtitle(for contact: UnitContact) -> String {
        let type = contact.isCustomer ? "Customer" : contact.isUnqualified ? "Unqualified prospect" : "Prospect"
        let knocks = contact.knockCount == 1 ? "1 knock" : "\(contact.knockCount) knocks"
        return "\(type) - \(knocks)"
    }

    private func statusIcon(for contact: UnitContact) -> String {
        if contact.isCustomer {
            return "star.fill"
        }

        return contact.isUnqualified ? "xmark.octagon.fill" : "person.crop.circle.badge.clock"
    }

    private func statusColor(for contact: UnitContact) -> Color {
        if contact.isCustomer {
            return .green
        }

        return contact.isUnqualified ? .red : .blue
    }
}
