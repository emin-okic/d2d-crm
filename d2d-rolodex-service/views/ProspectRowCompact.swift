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
    private let minRowHeight: CGFloat = 74

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(prospect.fullName)
                .font(.body).fontWeight(.medium)
                .lineLimit(1)

            Text(prospect.address)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            HStack(spacing: 10) {
                if !prospect.contactPhone.isEmpty {
                    Text("📞 \(formatPhoneNumber(prospect.contactPhone))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if !prospect.contactEmail.isEmpty {
                    Text("✉️ \(prospect.contactEmail)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: minRowHeight, alignment: .leading) // uniform width & height
    }

    private func formatPhoneNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        if digits.count == 10 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        }
        return raw
    }
}
