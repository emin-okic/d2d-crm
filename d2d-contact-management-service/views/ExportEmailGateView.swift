//
//  ExportEmailGateView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/2/26.
//

import SwiftUI

struct ExportEmailGateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""

    let onSuccess: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter your email to unlock exports")
                    .font(.title3)
                    .multilineTextAlignment(.center)

                TextField("you@email.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)

                Button("Unlock Export") {
                    let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed.contains("@") else { return }

                    EmailGateManager.shared.unlock(with: trimmed)

                    CloudKitEmailLogger.shared.log(
                        ExportEmailPayload(
                            email: trimmed,
                            timestamp: Date(),
                            source: "csv_export_gate"
                        )
                    )

                    onSuccess()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Unlock Export")
        }
    }
}
