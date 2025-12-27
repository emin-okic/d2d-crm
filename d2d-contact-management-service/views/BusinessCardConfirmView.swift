//
//  BusinessCardConfirmView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI

struct BusinessCardConfirmView: View {
    let draft: ProspectDraft
    let onConfirm: (ProspectDraft) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Confirm Prospect")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 8) {
                Text("Name: \(draft.fullName)")
                Text("Email: \(draft.email)")
                Text("Phone: \(draft.phone)")
                Text("Address: \(draft.address)")
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Confirm") {
                    onConfirm(draft)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
