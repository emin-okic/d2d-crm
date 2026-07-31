//
//  CustomerRowView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//

import SwiftUI

struct CustomerRowView: View {
    let customer: Customer

    private let minRowHeight: CGFloat = 92

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 10) {
                header
                addressLine
                footerLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: minRowHeight, alignment: .leading)
        .background(cardBackground)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.92), Color.cyan.opacity(0.76)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(initials)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(customer.fullName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 8)

            statusChip
        }
    }

    private var statusChip: some View {
        Text(statusText)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(statusColor)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.12))
            )
    }

    private var addressLine: some View {
        Label {
            Text(customer.address.isEmpty ? "No address" : customer.address)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "mappin.and.ellipse")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var footerLine: some View {
        VStack(alignment: .leading, spacing: 7) {
            contactLabel
            activityLabel
        }
    }

    private var contactLabel: some View {
        Label(primaryContactText, systemImage: primaryContactIcon)
            .font(.caption.weight(.medium))
            .foregroundStyle(primaryContactColor)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    private var activityLabel: some View {
        Label(activityText, systemImage: activityIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator).opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private var initials: String {
        let parts = customer.fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        let value = String(parts).uppercased()
        return value.isEmpty ? "C" : value
    }

    private var statusText: String {
        if nextAppointment != nil {
            return "Scheduled"
        }

        if !customer.phoneCalls.isEmpty || !customer.emailsSent.isEmpty || customer.sortedKnocks.first?.status == "Answered" {
            return "Active"
        }

        return customer.knockHistory.isEmpty ? "Customer" : "Follow up"
    }

    private var statusColor: Color {
        switch statusText {
        case "Scheduled": return .blue
        case "Active": return .green
        case "Follow up": return .orange
        default: return .teal
        }
    }

    private var primaryContactText: String {
        if !customer.contactPhone.isEmpty {
            return formatPhoneNumber(customer.contactPhone)
        }

        if !customer.contactEmail.isEmpty {
            return customer.contactEmail
        }

        return "No contact info"
    }

    private var primaryContactIcon: String {
        if !customer.contactPhone.isEmpty {
            return "phone.fill"
        }

        if !customer.contactEmail.isEmpty {
            return "envelope.fill"
        }

        return "person.crop.circle.badge.questionmark"
    }

    private var primaryContactColor: Color {
        customer.contactPhone.isEmpty && customer.contactEmail.isEmpty ? .secondary : .blue
    }

    private var activityText: String {
        if let appointment = nextAppointment {
            return "Next " + Self.dateFormatter.string(from: appointment.date)
        }

        if let latestKnock = customer.sortedKnocks.first {
            return "Last visit " + Self.dateFormatter.string(from: latestKnock.date)
        }

        return "No activity"
    }

    private var activityIcon: String {
        if nextAppointment != nil {
            return "calendar"
        }

        if !customer.sortedKnocks.isEmpty {
            return "figure.walk.arrival"
        }

        return "clock"
    }

    private var nextAppointment: Appointment? {
        customer.appointments
            .filter { $0.date >= .now }
            .sorted { $0.date < $1.date }
            .first
    }

    private func formatPhoneNumber(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        if digits.count == 10 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        }
        return raw
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
