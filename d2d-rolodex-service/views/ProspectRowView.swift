//
//  ProspectRowView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//


import SwiftUI
import SwiftData

struct ProspectRowView: View {
    let prospect: Prospect
    let onTap: () -> Void
    let onDoubleTap: () -> Void

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
            }
            
            if !prospect.contactEmail.isEmpty {
                Text("✉️ \(prospect.contactEmail)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            if !prospect.sortedKnocks.isEmpty {
                KnockDotsView(knocks: prospect.sortedKnocks)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 1, perform: onTap)
        .onTapGesture(count: 2, perform: onDoubleTap)
    }

    private func formatPhoneNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        if digits.count == 10 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        } else {
            return raw
        }
    }
}
