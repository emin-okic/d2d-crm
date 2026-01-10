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
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .imageScale(.large)
                }
            }

            Text(address)
                .font(.headline)
                .multilineTextAlignment(.center)

            Divider()

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(contacts) { contact in
                        Button {
                            onSelect(contact)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(displayName(for: contact))
                                        .font(.headline)
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
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: 280, height: 320)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(radius: 8)
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
