//
//  MapScorecardSelectorView.swift
//  d2d-studio
//
//  Created by Codex on 8/3/26.
//

import SwiftUI

struct MapScorecardSelectorView: View {
    let definitions: [MapScorecardDefinition]
    let selectedIDs: Set<String>
    let maxSelectionCount: Int
    let onToggle: (MapScorecardDefinition) -> Void
    let onRestoreDefaults: () -> Void
    let onClose: () -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 0), spacing: 10),
        count: 3
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(definitions) { definition in
                    let isSelected = selectedIDs.contains(definition.id)
                    MapScorecardSelectorTile(
                        definition: definition,
                        isSelected: isSelected,
                        isDisabled: isSelectionFull && isSelected == false,
                        onToggle: {
                            onToggle(definition)
                        }
                    )
                }
            }

            footer
        }
        .padding(14)
        .frame(maxWidth: 430, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.grid.3x2.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Scorecards")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("\(selectedIDs.count) of \(maxSelectionCount) active")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close Scorecard Selector")
        }
    }

    private var isSelectionFull: Bool {
        selectedIDs.count >= maxSelectionCount
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                onRestoreDefaults()
            } label: {
                Label("Defaults", systemImage: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                onClose()
            } label: {
                Label("Done", systemImage: "checkmark")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(Color.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private struct MapScorecardSelectorTile: View {
    let definition: MapScorecardDefinition
    let isSelected: Bool
    let isDisabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: definition.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(definition.color)
                        .frame(width: 32, height: 32)
                        .background(definition.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Spacer(minLength: 0)

                    Image(systemName: statusIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(statusColor)
                        .frame(width: 22, height: 22)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(definition.period.selectorTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(definition.metric.noun)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
            .background(tileBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? definition.color.opacity(0.75) : Color.white.opacity(0.28), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.48 : 1)
        .accessibilityLabel(accessibilityLabel)
    }

    private var statusIcon: String {
        if isSelected { return "checkmark.circle.fill" }
        return isDisabled ? "lock.circle" : "plus.circle"
    }

    private var statusColor: Color {
        if isSelected { return definition.color }
        return isDisabled ? .secondary.opacity(0.72) : .secondary
    }

    private var tileBackground: Color {
        if isSelected { return definition.color.opacity(0.12) }
        return Color(.secondarySystemBackground).opacity(isDisabled ? 0.52 : 0.82)
    }

    private var accessibilityLabel: String {
        if isDisabled { return "Maximum Scorecards Reached" }
        return "\(isSelected ? "Remove" : "Add") \(definition.title) Scorecard"
    }
}

private extension MapScorecardPeriod {
    var selectorTitle: String {
        switch self {
        case .daily:
            "Today"
        case .weekly:
            "Week"
        case .monthly:
            "Month"
        }
    }
}
