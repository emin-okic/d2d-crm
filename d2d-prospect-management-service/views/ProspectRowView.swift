//
//  ProspectRowFull.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/25/25.
//

import SwiftUI
import SwiftData

struct ProspectRowView: View {
    let prospect: Prospect
    private let minRowHeight: CGFloat = 96   // a touch taller for breathing room

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(prospect.fullName)
                .font(.headline)

            Text(prospect.address)
                .font(.subheadline)
                .foregroundColor(.gray)

            if !prospect.contactPhone.isEmpty {
                Text("📞 \(formatPhoneNumber(prospect.contactPhone))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }

            ProspectActivityMetricsView(
                knockCount: prospect.sortedKnocks.count,
                emailCount: prospect.emailsSent.count,
                phoneCallCount: prospect.phoneCallCount
            )
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: minRowHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1) // subtle border
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func formatPhoneNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        if digits.count == 10 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        }
        return raw
    }
}

private struct ProspectActivityMetricsView: View {
    let knockCount: Int
    let emailCount: Int
    let phoneCallCount: Int

    var body: some View {
        HStack(spacing: 14) {
            metric(systemImage: "door.left.hand.open", count: knockCount, color: .brown, label: "Knocks")
            metric(systemImage: "envelope", count: emailCount, color: .blue, label: "Emails sent")
            metric(systemImage: "phone", count: phoneCallCount, color: .green, label: "Calls made")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundColor(.secondary)
        .padding(.top, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(knockCount) knocks, \(emailCount) emails sent, \(phoneCallCount) calls made")
    }

    private func metric(systemImage: String, count: Int, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .foregroundColor(color)
                .frame(width: 17)
            Text("\(count)")
                .monospacedDigit()
        }
        .accessibilityLabel("\(count) \(label)")
    }
}
