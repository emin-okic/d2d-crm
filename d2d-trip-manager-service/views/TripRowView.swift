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
        HStack(alignment: .top, spacing: 10) {
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.blue)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 6) {
                    Label(trip.startAddress, systemImage: "circle.fill")
                    Label(trip.endAddress, systemImage: "mappin.circle.fill")
                    HStack {
                        Image(systemName: "car.fill")
                        Text("\(trip.miles, specifier: "%.1f") miles")
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 6)
        .background(isEditing && isSelected ? Color.red.opacity(0.06) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing { toggleSelection(trip) }
        }
    }
}
