//
//  ScorecardBar.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//
import SwiftUI

struct ScorecardBar: View {
    @Binding var isCustomizingScorecards: Bool

    @AppStorage("mapScorecardSelectionIDs") private var selectedScorecardIDs: String = ""
    @AppStorage("mapScorecardKnocksVisible") private var legacyKnocksVisible: Bool = true
    @AppStorage("mapScorecardSalesVisible") private var legacySalesVisible: Bool = true

    @State private var editingScorecard: MapScorecardDefinition?
    @State private var confirmingRemoval: MapScorecardDefinition?
    @State private var isShowingRestoreTargets = false

    private let maxScorecardCount = 4

    var body: some View {
        VStack(spacing: 10) {
            if visibleDefinitions.isEmpty && isShowingRestoreTargets == false {
                emptyScorecardRestoreZone
                    .transition(.opacity)
            } else {
                scorecardGrid
                    .transition(.scale(scale: 0.98).combined(with: .opacity))
            }

            if isShowingRestoreTargets {
                selectorPanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .top)
        .zIndex(1)
        .onAppear(perform: initializeSelectionIfNeeded)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: visibleDefinitions.map(\.id))
        .animation(.spring(response: 0.24, dampingFraction: 0.8), value: editingScorecard?.id)
        .animation(.spring(response: 0.24, dampingFraction: 0.8), value: isShowingRestoreTargets)
    }

    private var scorecardGrid: some View {
        Group {
            if visibleDefinitions.count == 3 {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ForEach(visibleDefinitions.prefix(2)) { definition in
                            scorecardSlot(for: definition, isExpanded: false)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    if let bannerDefinition = visibleDefinitions.last {
                        scorecardSlot(for: bannerDefinition, isExpanded: true)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(visibleDefinitions) { definition in
                        scorecardSlot(for: definition, isExpanded: visibleDefinitions.count == 1)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(maxWidth: visibleDefinitions.count == 1 ? .infinity : 420, alignment: .center)
    }

    private func scorecardSlot(for definition: MapScorecardDefinition, isExpanded: Bool) -> some View {
        VStack(spacing: 8) {
            MapAnalyticsTrackerView(
                definition: definition,
                isExpanded: isExpanded,
                isCustomizationActive: isCustomizingScorecards
            )
            .overlay {
                if editingScorecard == definition {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            Color.red,
                            style: StrokeStyle(lineWidth: 2, dash: [7, 5])
                        )
                }
            }
            .overlay(alignment: .topTrailing) {
                if editingScorecard == definition {
                    editControls(for: definition)
                        .padding(6)
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        beginEditing(definition)
                    }
            )

            if confirmingRemoval == definition {
                removePrompt(for: definition)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func editControls(for definition: MapScorecardDefinition) -> some View {
        HStack(spacing: 6) {
            Button {
                showSelector()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .blue)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose Map Scorecards")

            Button {
                requestRemovalConfirmation(for: definition)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(definition.title) Scorecard")
        }
    }

    private func removePrompt(for definition: MapScorecardDefinition) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(width: 30, height: 30)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("Remove \(definition.title)")
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
                    hide(definition)
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
        .frame(maxWidth: visibleDefinitions.count == 1 ? .infinity : 190)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
    }

    private var emptyScorecardRestoreZone: some View {
        Button {
            showSelector()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 38, height: 38)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("Choose scorecards")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color.blue, in: Circle())
            }
            .padding(12)
            .frame(maxWidth: 430, minHeight: 72, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.16), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose Map Scorecards")
    }

    private var selectorPanel: some View {
        MapScorecardSelectorView(
            definitions: MapScorecardDefinition.allCases,
            selectedIDs: Set(selectedIDs),
            maxSelectionCount: maxScorecardCount,
            onToggle: toggleSelection,
            onLimitReached: signalScorecardLimitReached,
            onRestoreDefaults: restoreDefaultSelection,
            onClose: closeSelector
        )
    }

    private var gridColumns: [GridItem] {
        let count = visibleDefinitions.count == 1 ? 1 : 2
        return Array(repeating: GridItem(.flexible(minimum: 0), spacing: 12), count: count)
    }

    private var visibleDefinitions: [MapScorecardDefinition] {
        selectedIDs.compactMap { MapScorecardDefinition.definition(for: $0) }
    }

    private var selectedIDs: [String] {
        selectedScorecardIDs
            .split(separator: ",")
            .map(String.init)
            .filter { MapScorecardDefinition.definition(for: $0) != nil }
    }

    private func initializeSelectionIfNeeded() {
        guard selectedScorecardIDs.isEmpty else { return }

        let migratedSelection = MapScorecardDefinition.defaultSelection.filter { definition in
            switch definition.metric {
            case .knocks:
                legacyKnocksVisible
            case .sales:
                legacySalesVisible
            case .streak:
                true
            }
        }

        setSelection(migratedSelection.isEmpty ? MapScorecardDefinition.defaultSelection : migratedSelection)
    }

    private func beginEditing(_ definition: MapScorecardDefinition) {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playScorecardSelectorOpen()
        editingScorecard = definition
        confirmingRemoval = nil
        isShowingRestoreTargets = false
        updateCustomizationState()
    }

    private func requestRemovalConfirmation(for definition: MapScorecardDefinition) {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playScorecardSelectorOpen()
        confirmingRemoval = definition
        updateCustomizationState()
    }

    private func cancelEditing() {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playScorecardSelectorClose()
        editingScorecard = nil
        confirmingRemoval = nil
        updateCustomizationState()
    }

    private func hide(_ definition: MapScorecardDefinition) {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playScorecardRemoved()
        setSelection(visibleDefinitions.filter { $0.id != definition.id })
        editingScorecard = nil
        confirmingRemoval = nil
        updateCustomizationState()
    }

    private func showSelector() {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playScorecardSelectorOpen()
        editingScorecard = nil
        confirmingRemoval = nil
        isShowingRestoreTargets = true
        updateCustomizationState()
    }

    private func closeSelector() {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playScorecardSelectorClose()
        isShowingRestoreTargets = false
        updateCustomizationState()
    }

    private func toggleSelection(_ definition: MapScorecardDefinition) {
        MapScreenHapticsController.shared.lightTap()

        if selectedIDs.contains(definition.id) {
            MapScreenSoundController.shared.playScorecardRemoved()
            setSelection(visibleDefinitions.filter { $0.id != definition.id })
        } else {
            guard visibleDefinitions.count < maxScorecardCount else {
                signalScorecardLimitReached()
                return
            }
            MapScreenSoundController.shared.playScorecardAdded()
            setSelection(visibleDefinitions + [definition])
        }
    }

    private func signalScorecardLimitReached() {
        MapScreenHapticsController.shared.bulkAddConfirmed()
        MapScreenSoundController.shared.playScorecardLimitReached()
    }

    private func restoreDefaultSelection() {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playScorecardAdded()
        setSelection(MapScorecardDefinition.defaultSelection)
    }

    private func setSelection(_ definitions: [MapScorecardDefinition]) {
        selectedScorecardIDs = definitions.map(\.id).joined(separator: ",")
    }

    private func updateCustomizationState() {
        isCustomizingScorecards = editingScorecard != nil || confirmingRemoval != nil || isShowingRestoreTargets
    }
}
