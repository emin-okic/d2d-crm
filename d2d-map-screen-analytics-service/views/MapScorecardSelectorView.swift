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
    let onLimitReached: () -> Void
    let onRestoreDefaults: () -> Void
    let onClose: () -> Void

    private let cardWidth: CGFloat = 210

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(definitions) { definition in
                        let isSelected = selectedIDs.contains(definition.id)
                        MapScorecardGalleryCard(
                            definition: definition,
                            isSelected: isSelected,
                            isDisabled: isSelectionFull && isSelected == false,
                            onToggle: {
                                onToggle(definition)
                            },
                            onLimitReached: onLimitReached
                        )
                        .frame(width: cardWidth)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .frame(height: 212)

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

private struct MapScorecardGalleryCard: View {
    let definition: MapScorecardDefinition
    let isSelected: Bool
    let isDisabled: Bool
    let onToggle: () -> Void
    let onLimitReached: () -> Void

    var body: some View {
        Button {
            if isDisabled {
                onLimitReached()
            } else {
                onToggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: definition.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [
                                    definition.color.opacity(0.95),
                                    definition.color.opacity(0.62)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .shadow(color: definition.color.opacity(isSelected ? 0.32 : 0.18), radius: 8, x: 0, y: 5)

                    Spacer(minLength: 0)

                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 11, weight: .bold))

                        Text(statusTitle)
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .frame(height: 25)
                    .background(statusBackground, in: Capsule())
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(definition.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)

                    Text(definition.description)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Label(definition.period.selectorTitle, systemImage: "calendar")
                    Label(definition.metric.noun, systemImage: definition.icon)
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(definition.color)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 198, alignment: .leading)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? definition.color.opacity(0.88) : Color.white.opacity(0.32), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(definition.color.opacity(isSelected ? 0.18 : 0.08))
                    .offset(x: -10, y: -12)
                    .allowsHitTesting(false)
            }
            .scaleEffect(isSelected ? 1.02 : 0.96)
            .shadow(color: definition.color.opacity(isSelected ? 0.22 : 0.08), radius: isSelected ? 14 : 8, x: 0, y: isSelected ? 9 : 5)
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.48 : 1)
        .accessibilityLabel(accessibilityLabel)
    }

    private var statusIcon: String {
        if isSelected { return "checkmark.circle.fill" }
        return isDisabled ? "lock.circle" : "plus.circle"
    }

    private var statusTitle: String {
        if isSelected { return "Picked" }
        return isDisabled ? "Full" : "Add"
    }

    private var statusColor: Color {
        if isSelected { return .white }
        return isDisabled ? .secondary.opacity(0.78) : definition.color
    }

    private var statusBackground: Color {
        if isSelected { return definition.color }
        return Color(.secondarySystemBackground).opacity(isDisabled ? 0.7 : 0.92)
    }

    private var cardBackground: LinearGradient {
        let base = Color(.secondarySystemBackground).opacity(isDisabled ? 0.52 : 0.88)

        return LinearGradient(
            colors: [
                isSelected ? definition.color.opacity(0.24) : base,
                base,
                definition.color.opacity(isSelected ? 0.16 : 0.07)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
