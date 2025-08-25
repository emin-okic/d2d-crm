//
//  ProspectRowCompact.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/25/25.
//

import SwiftUI
import SwiftData

struct ProspectRowCompact: View {
    let prospect: Prospect
    private let minRowHeight: CGFloat = 88   // ↑ from 74

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // a bit more breathing room
            Text(prospect.fullName)
                .font(.title3).fontWeight(.semibold)   // ↑ from .body

            Text(prospect.address)
                .font(.footnote)                       // ↑ from .caption
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                if !prospect.contactPhone.isEmpty {
                    Text("📞 \(formatPhoneNumber(prospect.contactPhone))")
                        .font(.caption)                // ↑ from .caption2
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if !prospect.contactEmail.isEmpty {
                    Text("✉️ \(prospect.contactEmail)")
                        .font(.caption)                // ↑ from .caption2
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, minHeight: minRowHeight, alignment: .leading)
    }

    private func formatPhoneNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        if digits.count == 10 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        }
        return raw
    }
}
