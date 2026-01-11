//
//  DailySalesTrackerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI
import SwiftData

struct DailySalesTrackerView: View {

    @Query private var allKnocks: [Knock]
    @State private var showSheet = false

    private var todaySalesCount: Int {
        let calendar = Calendar.current
        let today = Date()

        return allKnocks.filter {
            calendar.isDate($0.date, inSameDayAs: today) &&
            $0.status == "Converted To Sale"
        }.count
    }

    var body: some View {
        Button {
            
            // ✅ Haptics
            MapScreenHapticsController.shared.lightTap()
            
            // ✅ Sound
            MapScreenSoundController.shared.playPropertyOpen()
            
            showSheet = true
            
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Sales")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(todaySalesCount)")
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
        .sheet(isPresented: $showSheet) {
            DailySalesHourlyChartView()
                .presentationDetents([.fraction(0.25)])
                .presentationDragIndicator(.visible)
        }
    }
}
