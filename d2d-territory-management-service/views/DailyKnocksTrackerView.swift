//
//  DailyKnocksTrackerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI
import SwiftData

struct DailyKnocksTrackerView: View {

    @Query private var allKnocks: [Knock]

    private var todayKnockCount: Int {
        let calendar = Calendar.current
        let today = Date()

        return allKnocks.filter {
            calendar.isDate($0.date, inSameDayAs: today)
        }.count
    }

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: "door.left.hand.open")
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Knocks")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(todayKnockCount)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 4)
        }
        .buttonStyle(.plain)
    }
}
