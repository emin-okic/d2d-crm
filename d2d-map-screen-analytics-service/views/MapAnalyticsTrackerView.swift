//
//  MapAnalyticsTrackerView.swift
//  d2d-studio
//
//  Created by Codex on 8/2/26.
//

import SwiftUI
import SwiftData

struct MapAnalyticsTrackerView: View {
    let definition: MapScorecardDefinition
    var isExpanded: Bool = false
    var isCustomizationActive: Bool = false

    @Query private var allKnocks: [Knock]
    @State private var showSheet = false

    private var count: Int {
        if definition.metric == .streak {
            return KnockStreakCalculator.summary(from: allKnocks).displayedCurrentStreak
        }

        return MapAnalyticsCalculator.totalCount(from: allKnocks, for: definition)
    }

    var body: some View {
        Button {
            guard !isCustomizationActive else { return }

            MapScreenHapticsController.shared.lightTap()
            MapScreenSoundController.shared.playPropertyOpen()
            showSheet = true
        } label: {
            HStack(spacing: isExpanded ? 16 : 12) {
                Image(systemName: definition.icon)
                    .font(.system(size: isExpanded ? 24 : 19, weight: .semibold))
                    .foregroundStyle(definition.color)
                    .frame(width: isExpanded ? 50 : 36, height: isExpanded ? 50 : 36)
                    .background(Circle().fill(definition.color.opacity(0.14)))

                VStack(alignment: .leading, spacing: isExpanded ? 4 : 2) {
                    Text(definition.title)
                        .font(isExpanded ? .subheadline : .caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("\(count)")
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
                    .shadow(color: definition.color.opacity(0.14), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), definition.color.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            if definition.metric == .streak {
                KnockStreakSheetView()
                    .presentationDetents([.fraction(0.78), .large])
                    .presentationContentInteraction(.scrolls)
                    .presentationDragIndicator(.visible)
            } else {
                MapAnalyticsChartView(definition: definition)
                    .presentationDetents([.fraction(0.78), .large])
                    .presentationContentInteraction(.scrolls)
                    .presentationDragIndicator(.visible)
            }
        }
    }
}
