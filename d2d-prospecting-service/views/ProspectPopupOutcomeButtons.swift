//
//  OutcomeButtonsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/3/25.
//

import SwiftUI

struct ProspectPopupOutcomeButtons: View {
    let isCustomer: Bool
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("Select Knock Outcome")
                .font(.caption)
                .foregroundColor(.gray)

            HStack {
                Spacer()
                HStack(spacing: 16) {
                    iconButton(systemName: "house.slash.fill", label: "Not Home", color: .gray) {
                        onSelect("Wasn't Home")
                    }

                    if !isCustomer {
                        iconButton(systemName: "checkmark.seal.fill", label: "Sale", color: .green) {
                            onSelect("Converted To Sale")
                        }
                    }

                    iconButton(systemName: "calendar.badge.clock", label: "Follow Up", color: .orange) {
                        onSelect("Follow Up Later")
                    }
                }
                Spacer()
            }
        }
        .padding(.top, 4)
    }

    private func iconButton(systemName: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }
}
