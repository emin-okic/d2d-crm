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
                        colors: [Color.indigo.opacity(0.95), Color.teal.opacity(0.78)],
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
            Text(prospect.fullName)
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
            Text(prospect.address.isEmpty ? "No address" : prospect.address)
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
        let parts = prospect.fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        let value = String(parts).uppercased()
        return value.isEmpty ? "P" : value
    }

    private var statusText: String {
        if prospect.isUnqualified {
            return "Unqualified"
        }

        if nextAppointment != nil {
            return "Scheduled"
        }

        if prospect.sortedKnocks.first?.status == "Answered" {
            return "Engaged"
        }

        return prospect.knockHistory.isEmpty ? "New" : "Follow up"
    }

    private var statusColor: Color {
        switch statusText {
        case "Scheduled": return .blue
        case "Engaged": return .green
        case "Unqualified": return .red
        case "Follow up": return .orange
        default: return .indigo
        }
    }

    private var primaryContactText: String {
        if !prospect.contactPhone.isEmpty {
            return formatPhoneNumber(prospect.contactPhone)
        }

        if !prospect.contactEmail.isEmpty {
            return prospect.contactEmail
        }

        return "No contact info"
    }

    private var primaryContactIcon: String {
        if !prospect.contactPhone.isEmpty {
            return "phone.fill"
        }

        if !prospect.contactEmail.isEmpty {
            return "envelope.fill"
        }

        return "person.crop.circle.badge.questionmark"
    }

    private var primaryContactColor: Color {
        prospect.contactPhone.isEmpty && prospect.contactEmail.isEmpty ? .secondary : .blue
    }

    private var activityText: String {
        if let appointment = nextAppointment {
            return "Next " + Self.dateFormatter.string(from: appointment.date)
        }

        if let latestKnock = prospect.sortedKnocks.first {
            return "Last knock " + Self.dateFormatter.string(from: latestKnock.date)
        }

        return "No activity"
    }

    private var activityIcon: String {
        if nextAppointment != nil {
            return "calendar"
        }

        if !prospect.sortedKnocks.isEmpty {
            return "figure.walk.arrival"
        }

        return "clock"
    }

    private var nextAppointment: Appointment? {
        prospect.appointments
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
