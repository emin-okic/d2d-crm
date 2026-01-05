//
//  TripRowView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//
import SwiftUI

struct TripRowView: View {
    let trip: Trip
    let isEditing: Bool
    let isSelected: Bool
    let toggleSelection: (Trip) -> Void

    var body: some View {
        HStack(spacing: 12) {

            // Selection indicator (edit mode)
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 10) {

                // Date (meta)
                Text(trip.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Addresses
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.green)
                            .padding(.top, 6)

                        Text(trip.startAddress)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.subheadline)

                        Text(trip.endAddress)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }

                // Mileage badge
                HStack {
                    Image(systemName: "car.fill")
                        .font(.caption)

                    Text("\(trip.miles, specifier: "%.1f") miles")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.12))
                .foregroundColor(.blue)
                .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isEditing && isSelected
                                ? Color.blue.opacity(0.6)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                toggleSelection(trip)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
