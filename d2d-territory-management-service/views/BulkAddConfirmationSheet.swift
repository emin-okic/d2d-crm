//
//  BulkAddConfirmationSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/26/25.
//

import SwiftUI

struct BulkAddConfirmationSheet: View {
    let bulk: PendingBulkAdd
    let onConfirm: ([PendingAddProperty]) -> Void
    let onCancel: () -> Void

    @State private var selectedProperties: Set<UUID> = []

    private var selectedCount: Int {
        selectedProperties.count
    }

    private var hasProperties: Bool {
        !bulk.properties.isEmpty
    }

    private var isEveryPropertySelected: Bool {
        hasProperties && selectedCount == bulk.properties.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            content

            Divider()

            actionBar
        }
        .background(Color(.systemBackground))
        .onAppear {
            selectedProperties = Set(bulk.properties.map { $0.id })
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "house.and.flag.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.blue, Color(.systemBlue).opacity(0.14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Bulk Add Properties")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
            }

            if hasProperties {
                HStack(spacing: 10) {
                    metricPill(title: "Found", value: "\(bulk.properties.count)")
                    metricPill(title: "Selected", value: "\(selectedCount)")

                    Spacer(minLength: 8)

                    Button(isEveryPropertySelected ? "Clear" : "Select All") {
                        toggleAllProperties()
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    private var content: some View {
        Group {
            if hasProperties {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(bulk.properties) { property in
                            propertyRow(property)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .scrollIndicators(.visible)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(.secondary)

            Text("No New Addresses Found")
                .font(.headline)

            Text("This area does not have any new properties to add.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 34)
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button(role: .cancel) {
                MapScreenHapticsController.shared.lightTap()
                MapScreenSoundController.shared.playPropertyOpen()
                onCancel()
            } label: {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button {
                let selected = bulk.properties.filter { selectedProperties.contains($0.id) }
                MapScreenHapticsController.shared.propertyAdded()
                MapScreenSoundController.shared.playPropertyAdded()
                onConfirm(selected)
            } label: {
                Label("Add \(selectedCount)", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedProperties.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(.regularMaterial)
    }

    private var summaryText: String {
        guard hasProperties else { return "Try a different radius placement." }
        return "Review addresses before adding."
    }

    private func metricPill(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground), in: Capsule())
    }

    private func propertyRow(_ property: PendingAddProperty) -> some View {
        let isSelected = selectedProperties.contains(property.id)

        return Button {
            toggleSelection(property)
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 24, height: 24)

                MarqueeAddressText(text: property.address)
                    .frame(height: 20)

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(rowBackground(isSelected: isSelected))
            .overlay(rowBorder(isSelected: isSelected))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func rowBackground(isSelected: Bool) -> some ShapeStyle {
        isSelected ? Color(.systemBlue).opacity(0.08) : Color(.systemBackground)
    }

    private func rowBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(isSelected ? Color.blue.opacity(0.36) : Color(.separator).opacity(0.36), lineWidth: 1)
    }

    private func toggleAllProperties() {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playPropertyOpen()

        if isEveryPropertySelected {
            selectedProperties.removeAll()
        } else {
            selectedProperties = Set(bulk.properties.map { $0.id })
        }
    }

    private func toggleSelection(_ property: PendingAddProperty) {
        if selectedProperties.contains(property.id) {
            selectedProperties.remove(property.id)
        } else {
            selectedProperties.insert(property.id)
        }

        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playPropertyOpen()
    }
}

private struct MarqueeAddressText: View {
    let text: String

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var scrollTask: Task<Void, Never>?

    private let font = Font.subheadline.weight(.semibold)
    private let scrollDelay: UInt64 = 900_000_000
    private let resetDelay: UInt64 = 600_000_000

    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .font(font)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: offset)
                .background(widthReader)
                .clipped()
                .onAppear {
                    containerWidth = geometry.size.width
                    restartScrollIfNeeded()
                }
                .onChange(of: geometry.size.width) { _, newWidth in
                    containerWidth = newWidth
                    restartScrollIfNeeded()
                }
                .onChange(of: textWidth) { _, _ in
                    restartScrollIfNeeded()
                }
                .onDisappear {
                    scrollTask?.cancel()
                    scrollTask = nil
                }
        }
        .clipped()
    }

    private var widthReader: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: AddressTextWidthPreferenceKey.self, value: geometry.size.width)
        }
        .onPreferenceChange(AddressTextWidthPreferenceKey.self) { width in
            textWidth = width
        }
    }

    private func restartScrollIfNeeded() {
        scrollTask?.cancel()
        scrollTask = nil

        guard textWidth > containerWidth + 8 else {
            withAnimation(.easeOut(duration: 0.16)) {
                offset = 0
            }
            return
        }

        let travelDistance = textWidth - containerWidth + 18
        let duration = min(max(Double(travelDistance) / 34, 1.4), 4.5)

        offset = 0
        scrollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: scrollDelay)
            guard !Task.isCancelled else { return }

            withAnimation(.linear(duration: duration)) {
                offset = -travelDistance
            }

            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            try? await Task.sleep(nanoseconds: resetDelay)
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.2)) {
                offset = 0
            }
        }
    }
}

private struct AddressTextWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
