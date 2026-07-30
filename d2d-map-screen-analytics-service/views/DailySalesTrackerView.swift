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

    private var todayKnocks: [Knock] {
        let calendar = Calendar.current
        let today = Date()

        return allKnocks.filter {
            calendar.isDate($0.date, inSameDayAs: today)
        }
    }

    private var todaySalesCount: Int {
        todayKnocks.filter { isSale($0) }.count
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
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.green.opacity(0.14)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Sales")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("\(todaySalesCount)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 10)
                    .shadow(color: Color.green.opacity(0.16), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), Color.green.opacity(0.24)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            DailySalesHourlyChartView()
                .presentationDetents([.fraction(0.78), .large])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
        }
    }

    private func isSale(_ knock: Knock) -> Bool {
        knock.status.lowercased().contains("converted") ||
        knock.status.lowercased().contains("sale")
    }
}
