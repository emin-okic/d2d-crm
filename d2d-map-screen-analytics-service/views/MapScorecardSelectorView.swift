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
                    MapScorecardSelectorTile(
                        definition: definition,
                        isSelected: selectedIDs.contains(definition.id),
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

                Text("\(selectedIDs.count) active")
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

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? definition.color : .secondary)
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
        .accessibilityLabel("\(isSelected ? "Remove" : "Add") \(definition.title) Scorecard")
    }

    private var tileBackground: Color {
        isSelected ? definition.color.opacity(0.12) : Color(.secondarySystemBackground).opacity(0.82)
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
