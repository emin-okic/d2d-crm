//
//  PhoneActionSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/28/26.
//

import SwiftUI
import PhoneNumberKit

struct PhoneActionSheet: View {

    let context: PhoneActionContext

    let onCall: () -> Void
    let onEdit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            Text("Call \(context.displayName)?")
                .font(.headline)

            Text(PhoneValidator.formatted(context.getPhone()))
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {

                Button("Edit Number") {
                    onEdit()
                }
                .buttonStyle(.bordered)

                Button("Call") {
                    onCall()
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Cancel", role: .cancel) {
                onCancel()
            }
            .padding(.top, 4)
        }
        .padding()
    }
}
