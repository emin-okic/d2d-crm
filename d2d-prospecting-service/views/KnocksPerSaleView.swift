//
//  KnocksPerSaleView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/5/25.
//
import SwiftUI

struct KnocksPerSaleView: View {
    let count: Int
    let hasFirstSignup: Bool

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: "hand.tap")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Knocks Per Sale")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(hasFirstSignup ? "\(count)" : "–")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 4)
        }
        .buttonStyle(.plain)
    }
}
