//
//  MultiContactPopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/10/26.
//

import SwiftUI

struct MultiContactPopupView: View {
    let address: String
    let contacts: [UnitContact]
    let onSelect: (UnitContact) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(address)
                        .font(.headline)
                        .lineLimit(2)

                    Text("\(contacts.count) contacts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Contact list
            ForEach(contacts) { contact in
                Button {
                    onSelect(contact)
                } label: {
                    contactRow(contact)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }

    // MARK: - Row

    @ViewBuilder
    private func contactRow(_ contact: UnitContact) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName(for: contact))
                    .font(.body)
                    .foregroundStyle(.primary)

                Text(contact.list)
                    .font(.caption)
                    .foregroundStyle(contact.isCustomer ? .green : .secondary)
            }

            Spacer()

            if contact.knockCount > 0 {
                Text("\(contact.knockCount)")
                    .font(.caption.bold())
                    .padding(6)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Circle())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func displayName(for contact: UnitContact) -> String {
        switch contact {
        case .prospect(let p):
            return p.fullName.isEmpty ? "Unnamed Prospect" : p.fullName
        case .customer(let c):
            return c.fullName
        }
    }
}
