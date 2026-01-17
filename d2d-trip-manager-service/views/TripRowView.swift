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
    let openDetails: (Trip) -> Void   // 👈 NEW

    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(trip.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.green)
                            .padding(.top, 6)

                        Text(trip.startAddress)
                            .font(.subheadline)
                            .lineLimit(2)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)

                        Text(trip.endAddress)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                }

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
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                
                TripManagerHapticsController.shared.lightTap()
                TripManagerSoundController.shared.playSound1()
                
                toggleSelection(trip)
                
            } else {
                
                TripManagerHapticsController.shared.lightTap()
                TripManagerSoundController.shared.playSound1()
                
                openDetails(trip)   // 👈 OPEN DETAILS
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
