//
//  ContactActivityMetricsView.swift
//  d2d-studio
//
//  Created by Codex on 8/26/26.
//

import SwiftUI

struct ContactActivityMetricsView: View {
    let knockCount: Int
    let emailCount: Int
    let phoneCallCount: Int

    var body: some View {
        HStack(spacing: 6) {
            metric(
                systemImage: "door.left.hand.open",
                count: knockCount,
                title: "Knocks",
                color: .brown
            )

            metric(
                systemImage: "envelope.fill",
                count: emailCount,
                title: "Emails",
                color: .blue
            )

            metric(
                systemImage: "phone.fill",
                count: phoneCallCount,
                title: "Calls",
                color: .green
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(knockCount) knocks, \(emailCount) emails sent, \(phoneCallCount) calls made")
    }

    private func metric(systemImage: String, count: Int, title: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 18, height: 18)
                .background(color.opacity(0.12), in: Circle())

            Text("\(count)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .monospacedDigit()

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.14), lineWidth: 1)
        )
        .accessibilityLabel("\(count) \(title)")
    }
}
