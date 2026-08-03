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
    
    @State private var showSheet = false

    var isExpanded: Bool = false
    var isCustomizationActive: Bool = false

    private var todayKnockCount: Int {
        let calendar = Calendar.current
        let today = Date()

        return allKnocks.filter {
            calendar.isDate($0.date, inSameDayAs: today)
        }.count
    }

    var body: some View {
        Button {
            guard !isCustomizationActive else { return }
            
            // ✅ Haptics
            MapScreenHapticsController.shared.lightTap()
            
            // ✅ Sound
            MapScreenSoundController.shared.playPropertyOpen()
            
            showSheet = true
        } label: {
            HStack(spacing: isExpanded ? 16 : 12) {
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: isExpanded ? 24 : 19, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: isExpanded ? 50 : 36, height: isExpanded ? 50 : 36)
                    .background(Circle().fill(Color.blue.opacity(0.14)))

                VStack(alignment: .leading, spacing: isExpanded ? 4 : 2) {
                    Text("Today's Knocks")
                        .font(isExpanded ? .subheadline : .caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("\(todayKnockCount)")
                        .font(isExpanded ? .largeTitle.weight(.bold) : .title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, isExpanded ? 18 : 16)
            .padding(.vertical, isExpanded ? 14 : 10)
            .frame(maxWidth: isExpanded ? .infinity : nil, minHeight: isExpanded ? 88 : nil, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 10)
                    .shadow(color: Color.blue.opacity(0.14), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), Color.blue.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            DailyKnockHourlyChartView()
                .presentationDetents([.fraction(0.78), .large])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
        }
    }
}
