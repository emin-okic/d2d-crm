//
//  CustomerRowView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//

import SwiftUI

struct CustomerRowView: View {
    let customer: Customer
    private let minRowHeight: CGFloat = 96   // identical to ProspectRowView

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(customer.fullName)
                .font(.headline)

            Text(customer.address)
                .font(.subheadline)
                .foregroundColor(.gray)

            if !customer.contactPhone.isEmpty {
                Text("📞 \(formatPhoneNumber(customer.contactPhone))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }

            if !customer.contactEmail.isEmpty {
                Text("✉️ \(customer.contactEmail)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }

            // Optional knock history dots for parity (if you want parity)
            if !customer.knockHistory.isEmpty {
                KnockDotsView(knocks: customer.knockHistory)
            }
            
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: minRowHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 4,
                    x: 0,
                    y: 2
                )
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
