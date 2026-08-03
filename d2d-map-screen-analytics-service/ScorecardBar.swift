//
//  ScorecardBar.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//
import SwiftUI

struct ScorecardBar: View {
    @AppStorage("mapScorecardKnocksVisible") private var isKnocksVisible: Bool = true
    @AppStorage("mapScorecardSalesVisible") private var isSalesVisible: Bool = true

    @State private var editingScorecard: MapScorecardKind?
    @State private var isShowingRestoreTargets = false

    private enum MapScorecardKind: String, Identifiable, CaseIterable {
        case knocks
        case sales

        var id: String { rawValue }

        var title: String {
            switch self {
            case .knocks:
                "Today's Knocks"
            case .sales:
                "Today's Sales"
            }
        }

        var icon: String {
            switch self {
            case .knocks:
                "door.left.hand.open"
            case .sales:
                "checkmark.seal.fill"
            }
        }

        var color: Color {
            switch self {
            case .knocks:
                .blue
            case .sales:
                .green
            }
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            if visibleKinds.isEmpty {
                restoreBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                scorecardStack
                    .transition(.scale(scale: 0.98).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .top)
        .zIndex(1)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: visibleKinds.map(\.id))
        .animation(.spring(response: 0.24, dampingFraction: 0.8), value: editingScorecard?.id)
        .animation(.spring(response: 0.24, dampingFraction: 0.8), value: isShowingRestoreTargets)
    }

    private var scorecardStack: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(visibleKinds) { kind in
                scorecardSlot(for: kind)
                    .frame(maxWidth: visibleKinds.count == 1 ? .infinity : 190)
            }
        }
        .frame(maxWidth: visibleKinds.count == 1 ? .infinity : 420, alignment: .center)
    }

    private func scorecardSlot(for kind: MapScorecardKind) -> some View {
        VStack(spacing: 8) {
            scorecard(for: kind)
                .overlay {
                    if editingScorecard == kind {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                Color.red,
                                style: StrokeStyle(lineWidth: 2, dash: [7, 5])
                            )
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if editingScorecard == kind {
                        Button {
                            hide(kind)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .red)
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.plain)
                        .padding(6)
                        .accessibilityLabel("Remove \(kind.title) Scorecard")
                    }
                }
                .contentShape(Rectangle())
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            beginEditing(kind)
                        }
                )

            if editingScorecard == kind {
                removePrompt(for: kind)
                    .transition(.move(edge: .top).combined(with: .opacity))

                if hiddenKinds.isEmpty == false {
                    restoreTargetRow(for: hiddenKinds)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    @ViewBuilder
    private func scorecard(for kind: MapScorecardKind) -> some View {
        switch kind {
        case .knocks:
            DailyKnocksTrackerView(isExpanded: visibleKinds.count == 1)
        case .sales:
            DailySalesTrackerView(isExpanded: visibleKinds.count == 1)
        }
    }

    private func removePrompt(for kind: MapScorecardKind) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(width: 30, height: 30)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("Remove \(kind.title)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            HStack(spacing: 8) {
                Button {
                    cancelEditing()
                } label: {
                    Text("Cancel")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button {
                    hide(kind)
                } label: {
                    Text("Remove")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
                .buttonStyle(.plain)
                .background(Color.red, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(12)
        .frame(maxWidth: visibleKinds.count == 1 ? .infinity : 190)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
    }

    private var restoreBanner: some View {
        VStack(spacing: 10) {
            Button {
                requestRestoreTargets()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 54, height: 54)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.blue.opacity(0.24), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 7)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        requestRestoreTargets()
                    }
            )
            .accessibilityLabel("Add Scorecards")

            if isShowingRestoreTargets {
                restoreTargetRow(for: MapScorecardKind.allCases)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func restoreTargetRow(for kinds: [MapScorecardKind]) -> some View {
        HStack(spacing: 10) {
            ForEach(kinds) { kind in
                restoreTarget(for: kind)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func restoreTarget(for kind: MapScorecardKind) -> some View {
        Button {
            restore(kind)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: kind.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(kind.color)

                Text(kind.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(kind.color)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(kind.color.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        kind.color,
                        style: StrokeStyle(lineWidth: 1.6, dash: [6, 5])
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(kind.title) Scorecard")
    }

    private var visibleKinds: [MapScorecardKind] {
        MapScorecardKind.allCases.filter { isVisible($0) }
    }

    private var hiddenKinds: [MapScorecardKind] {
        MapScorecardKind.allCases.filter { !isVisible($0) }
    }

    private func isVisible(_ kind: MapScorecardKind) -> Bool {
        switch kind {
        case .knocks:
            isKnocksVisible
        case .sales:
            isSalesVisible
        }
    }

    private func beginEditing(_ kind: MapScorecardKind) {
        MapScreenHapticsController.shared.lightTap()
        editingScorecard = kind
        isShowingRestoreTargets = false
    }

    private func cancelEditing() {
        MapScreenHapticsController.shared.lightTap()
        editingScorecard = nil
    }

    private func hide(_ kind: MapScorecardKind) {
        MapScreenHapticsController.shared.lightTap()
        switch kind {
        case .knocks:
            isKnocksVisible = false
        case .sales:
            isSalesVisible = false
        }
        editingScorecard = nil
    }

    private func requestRestoreTargets() {
        MapScreenHapticsController.shared.lightTap()
        isShowingRestoreTargets = true
    }

    private func restore(_ kind: MapScorecardKind) {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playPropertyOpen()
        switch kind {
        case .knocks:
            isKnocksVisible = true
        case .sales:
            isSalesVisible = true
        }
        isShowingRestoreTargets = false
    }
}
