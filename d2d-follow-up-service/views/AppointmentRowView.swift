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
    private let minRowHeight: CGFloat = 96

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Follow Up With \(appt.prospect?.fullName ?? appt.title)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(appt.prospect?.address ?? appt.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(appt.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: minRowHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isEditing && isSelected ? Color.red.opacity(0.06) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
