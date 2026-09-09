//
//  AppointmentRowView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//
import SwiftUI
import SwiftData

struct AppointmentRowView: View {
    let appt: Appointment
    var isEditing: Bool = false
    var isSelected: Bool = false

    private let minRowHeight: CGFloat = 104

    private var accentColor: Color {
        let palette: [Color] = [.blue, .purple, .pink, .orange, .teal, .green, .indigo, .mint]
        let index = Int(appt.id.uuid.0) % palette.count
        return palette[index]
    }

    private var contactName: String {
        if let prospectName = appt.prospect?.fullName, !prospectName.isEmpty {
            return prospectName
        }

        if let customerName = appt.customer?.fullName, !customerName.isEmpty {
            return customerName
        }

        return appt.clientName.isEmpty ? appt.title : appt.clientName
    }

    private var rowTitle: String {
        appt.title.isEmpty ? "Follow Up With \(contactName)" : appt.title
    }

    private var rowLocation: String {
        if let prospectAddress = appt.prospect?.address, !prospectAddress.isEmpty {
            return prospectAddress
        }

        if let customerAddress = appt.customer?.address, !customerAddress.isEmpty {
            return customerAddress
        }

        return appt.location
    }

    private var isCompleted: Bool {
        appt.isCompleted
    }

    private var statusColor: Color {
        isCompleted ? .green : accentColor
    }

    private var rowFillColor: Color {
        if isEditing && isSelected {
            return Color.red.opacity(0.08)
        }

        return isCompleted ? Color(.secondarySystemGroupedBackground) : accentColor.opacity(0.14)
    }

    private var rowStrokeColor: Color {
        if isEditing && isSelected {
            return Color.red.opacity(0.45)
        }

        return isCompleted ? Color.green.opacity(0.26) : accentColor.opacity(0.24)
    }

    private var completedStatusText: String {
        if let completedAt = appt.completedAt {
            return "Completed \(completedAt.formatted(date: .omitted, time: .shortened))"
        }

        return "Completed"
    }

    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? .red : accentColor)
                    .frame(width: 28, height: 28)
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(statusColor)
                .frame(width: 5)
                .opacity(isCompleted ? 0.62 : 1)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.green)
                                .accessibilityHidden(true)
                        }

                        Text(rowTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(isCompleted ? .secondary : .primary)
                            .strikethrough(isCompleted, color: .secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Text(appt.date.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isCompleted ? .secondary : accentColor)
                        .lineLimit(1)
                }

                Label(contactName, systemImage: "person.crop.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .opacity(isCompleted ? 0.72 : 1)

                if !rowLocation.isEmpty {
                    Label(rowLocation, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .opacity(isCompleted ? 0.72 : 1)
                }

                if isCompleted {
                    Label(completedStatusText, systemImage: "checkmark.seal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: minRowHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(rowFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(rowStrokeColor, lineWidth: 1)
                )
                .shadow(color: statusColor.opacity(isCompleted ? 0.08 : 0.16), radius: 10, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityHint(isCompleted ? "Completed meeting" : "")
    }
}
