//
//  ObjectionHeaderCard.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI

struct ObjectionHeaderCard: View {
    let objection: Objection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(objection.text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                confidenceBadge
            }

            ProgressView(value: objection.levelProgress)
                .tint(.blue)

            Text(progressDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var confidenceBadge: some View {
        Label("Level \(objection.confidenceLevel)", systemImage: "shield.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(.blue)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.blue.opacity(0.12), in: Capsule())
            .accessibilityLabel("Objection confidence level \(objection.confidenceLevel) of \(Objection.maximumLevel)")
    }

    private var progressDescription: String {
        guard let remaining = objection.responsesUntilNextLevel else {
            return "Maximum confidence reached"
        }

        let responseLabel = remaining == 1 ? "response" : "responses"
        return "\(remaining) more \(responseLabel) to Level \(objection.confidenceLevel + 1)"
    }
}
