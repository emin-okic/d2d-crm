//
//  WriteResponsePracticeView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI
import SwiftData

struct WriteResponsePracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var objection: Objection

    @State private var userResponse = ""
    @State private var didSubmit = false

    var body: some View {
        VStack(spacing: 24) {

            ProgressHeader(step: 1, total: 1)

            VStack(spacing: 12) {
                Text("Respond to this objection")
                    .font(.headline)

                Text("“\(objection.text)”")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Your response")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $userResponse)
                    .scrollContentBackground(.hidden)
                    .padding()
                    .frame(minHeight: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.3))
                    )
            }

            Spacer()

            Button {
                submit()
            } label: {
                Text(didSubmit ? "Saved!" : "Submit Response")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(didSubmit ? Color.green : Color.blue)
                    )
                    .foregroundColor(.white)
            }
            .disabled(userResponse.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
        .navigationBarBackButtonHidden()
    }

    private func submit() {
        objection.addResponse(userResponse)   // add user-written response
        objection.rotateResponse()            // pick a random one from the set
        try? modelContext.save()

        withAnimation {
            didSubmit = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}
