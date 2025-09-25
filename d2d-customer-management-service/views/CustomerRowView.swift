//
//  CustomerRowView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/17/25.
//

import SwiftUI
import SwiftData

struct CustomerRowView: View {
    let customer: Customer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(customer.fullName)
                .font(.headline)

            Text(customer.address)
                .font(.subheadline)
                .foregroundColor(.gray)

            if !customer.contactPhone.isEmpty {
                Text("📞 \(formatPhoneNumber(customer.contactPhone))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            if !customer.contactEmail.isEmpty {
                Text("✉️ \(customer.contactEmail)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatPhoneNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        if digits.count == 10 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        }
        return raw
    }
}
