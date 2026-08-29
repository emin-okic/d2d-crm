//
//  ContactAddressPredictiveTextField.swift
//  d2d-studio
//
//  Created by Codex on 8/29/26.
//

import SwiftUI
import MapKit

struct ContactAddressPredictiveTextField: View {
    @Binding var address: String
    @FocusState.Binding var isFocused: Bool
    @ObservedObject var searchVM: SearchCompleterViewModel
    var placeholder: String = "123 Main St"
    var onPredictionAccepted: (() -> Void)?

    private var prediction: MKLocalSearchCompletion? {
        searchVM.results.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(placeholder, text: $address, axis: .vertical)
                .focused($isFocused)
                .lineLimit(1...3)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .onChange(of: address) { _, newValue in
                    searchVM.updateQuery(newValue)
                }

            if isFocused, let prediction {
                Button {
                    acceptPrediction(prediction)
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tint)
                            .frame(width: 18, height: 18)
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(prediction.title)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)

                            if !prediction.subtitle.isEmpty {
                                Text(prediction.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }

                        Spacer(minLength: 8)

                        Image(systemName: "return")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Use suggested address \(prediction.title)")
            }
        }
    }

    private func acceptPrediction(_ prediction: MKLocalSearchCompletion) {
        Task {
            if let resolved = await SearchBarController.resolveAddress(from: prediction) {
                address = resolved
                searchVM.clear()
                isFocused = false
                onPredictionAccepted?()
            }
        }
    }
}
