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
        VStack(alignment: .leading, spacing: 8) {
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

            if !prospect.contactEmail.isEmpty {
                Text("✉️ \(prospect.contactEmail)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }

            if !prospect.sortedKnocks.isEmpty {
                KnockDotsView(knocks: prospect.sortedKnocks)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: minRowHeight, alignment: .leading)
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
