//
//  DetailsScorecardCustomizationView.swift
//  d2d-studio
//
//  Created by Codex on 8/2/26.
//

import SwiftUI

struct DetailsScorecardItem: Identifiable, Equatable {
    enum Kind: String {
        case meetings
        case knocks
    }

    let kind: Kind
    let title: String
    let value: String
    let icon: String
    let color: Color
    let action: () -> Void

    var id: String { kind.rawValue }

    static func == (lhs: DetailsScorecardItem, rhs: DetailsScorecardItem) -> Bool {
        lhs.kind == rhs.kind &&
        lhs.title == rhs.title &&
        lhs.value == rhs.value &&
        lhs.icon == rhs.icon
    }
}

struct DetailsScorecardCustomizationView: View {
    let items: [DetailsScorecardItem]
    let title: String

    @AppStorage private var isMeetingsVisible: Bool
    @AppStorage private var isKnocksVisible: Bool

    @State private var isEditingScorecards = false

    init(
        storagePrefix: String,
        title: String = "Scorecards",
        items: [DetailsScorecardItem]
    ) {
        self.items = items
        self.title = title
        _isMeetingsVisible = AppStorage(wrappedValue: true, "\(storagePrefix).scorecards.meetings.visible")
        _isKnocksVisible = AppStorage(wrappedValue: true, "\(storagePrefix).scorecards.knocks.visible")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if visibleItems.isEmpty {
                restorePanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                scorecardGrid
                    .transition(.scale(scale: 0.98).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: visibleItems.map(\.id))
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: isEditingScorecards)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Label(title, systemImage: "slider.horizontal.3")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if hiddenItems.isEmpty == false {
                Button {
                    restoreAll()
                } label: {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityLabel("Restore All Scorecards")
            }

            Button {
                ContactScreenHapticsController.shared.lightTap()
                isEditingScorecards.toggle()
            } label: {
                Image(systemName: isEditingScorecards ? "checkmark.circle.fill" : "wand.and.stars")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .foregroundStyle(isEditingScorecards ? .green : .primary)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel(isEditingScorecards ? "Done Customizing Scorecards" : "Customize Scorecards")
        }
    }

    private var scorecardGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(visibleItems) { item in
                DetailsCustomizableScorecard(
                    item: item,
                    isExpanded: visibleItems.count == 1,
                    isEditing: isEditingScorecards,
                    onRemove: {
                        hide(item.kind)
                    }
                )
                .id(item.id)
            }
        }
    }

    private var restorePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Scorecards hidden")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Bring back either card or restore the full set.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                ForEach(hiddenItems) { item in
                    Button {
                        show(item.kind)
                    } label: {
                        Label(item.title, systemImage: item.icon)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(item.color)
                    .background(item.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
    }

    private var gridColumns: [GridItem] {
        let visibleCount = visibleItems.count
        return Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: 12),
            count: visibleCount == 1 ? 1 : 2
        )
    }

    private var visibleItems: [DetailsScorecardItem] {
        items.filter { isVisible($0.kind) }
    }

    private var hiddenItems: [DetailsScorecardItem] {
        items.filter { !isVisible($0.kind) }
    }

    private func isVisible(_ kind: DetailsScorecardItem.Kind) -> Bool {
        switch kind {
        case .meetings:
            isMeetingsVisible
        case .knocks:
            isKnocksVisible
        }
    }

    private func hide(_ kind: DetailsScorecardItem.Kind) {
        ContactScreenHapticsController.shared.lightTap()
        setVisible(false, for: kind)

        if visibleItems.count <= 1 {
            isEditingScorecards = false
        }
    }

    private func show(_ kind: DetailsScorecardItem.Kind) {
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()
        setVisible(true, for: kind)
        isEditingScorecards = false
    }

    private func restoreAll() {
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()
        isMeetingsVisible = true
        isKnocksVisible = true
        isEditingScorecards = false
    }

    private func setVisible(_ isVisible: Bool, for kind: DetailsScorecardItem.Kind) {
        switch kind {
        case .meetings:
            isMeetingsVisible = isVisible
        case .knocks:
            isKnocksVisible = isVisible
        }
    }
}

private struct DetailsCustomizableScorecard: View {
    let item: DetailsScorecardItem
    let isExpanded: Bool
    let isEditing: Bool
    let onRemove: () -> Void

    var body: some View {
        Button {
            guard !isEditing else { return }
            item.action()
        } label: {
            HStack(spacing: isExpanded ? 16 : 12) {
                Image(systemName: item.icon)
                    .font(.system(size: isExpanded ? 24 : 18, weight: .semibold))
                    .foregroundStyle(item.color)
                    .frame(width: isExpanded ? 46 : 32, height: isExpanded ? 46 : 32)
                    .background(item.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: isExpanded ? 4 : 2) {
                    Text(item.title)
                        .font(isExpanded ? .subheadline : .caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(item.value)
                        .font(isExpanded ? .largeTitle.weight(.bold) : .title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, isExpanded ? 16 : 14)
            .padding(.vertical, isExpanded ? 14 : 10)
            .frame(maxWidth: .infinity, minHeight: isExpanded ? 96 : 72, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(item.color.opacity(isEditing ? 0.55 : 0.25), lineWidth: isEditing ? 1.5 : 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .overlay(alignment: .topTrailing) {
                if isEditing {
                    removeButton
                        .padding(6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.title) Scorecard")
        .accessibilityHint(isEditing ? "Double tap to remove this scorecard" : "Double tap to open details")
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    onRemove()
                }
        )
    }

    private var removeButton: some View {
        Button {
            onRemove()
        } label: {
            Image(systemName: "minus.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .red)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(item.title) Scorecard")
    }
}
