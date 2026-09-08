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
    var isCompact: Bool = false

    @Query private var allKnocks: [Knock]
    @State private var showSheet = false

    private var count: Int {
        if definition.metric == .streak {
            return KnockStreakCalculator.summary(from: allKnocks).displayedCurrentStreak
        }

        return MapAnalyticsCalculator.totalCount(from: allKnocks, for: definition)
    }

    private var iconSize: CGFloat {
        isCompact ? 28 : (isExpanded ? 50 : 36)
    }

    private var iconFontSize: CGFloat {
        isCompact ? 15 : (isExpanded ? 24 : 19)
    }

    private var horizontalPadding: CGFloat {
        isCompact ? 11 : (isExpanded ? 18 : 16)
    }

    private var verticalPadding: CGFloat {
        isCompact ? 7 : (isExpanded ? 14 : 10)
    }

    private var cornerRadius: CGFloat {
        isCompact ? 15 : 18
    }

    var body: some View {
        Button {
            guard !isCustomizationActive else { return }

            MapScreenHapticsController.shared.lightTap()
            MapScreenSoundController.shared.playPropertyOpen()
            showSheet = true
        } label: {
            HStack(spacing: isCompact ? 8 : (isExpanded ? 16 : 12)) {
                Image(systemName: definition.icon)
                    .font(.system(size: iconFontSize, weight: .semibold))
                    .foregroundStyle(definition.color)
                    .frame(width: iconSize, height: iconSize)
                    .background(Circle().fill(definition.color.opacity(0.14)))

                VStack(alignment: .leading, spacing: isCompact ? 1 : (isExpanded ? 4 : 2)) {
                    Text(definition.title)
                        .font(isCompact ? .caption2.weight(.semibold) : (isExpanded ? .subheadline : .caption))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("\(count)")
                        .font(isCompact ? .headline.weight(.bold) : (isExpanded ? .largeTitle.weight(.bold) : .title2.weight(.bold)))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: isExpanded ? .infinity : nil, minHeight: isCompact ? 46 : (isExpanded ? 88 : nil), alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(isCompact ? 0.13 : 0.18), radius: isCompact ? 10 : 16, x: 0, y: isCompact ? 5 : 10)
                    .shadow(color: definition.color.opacity(isCompact ? 0.1 : 0.14), radius: isCompact ? 5 : 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
