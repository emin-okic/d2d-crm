//
//  ToggleChipsView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//
import SwiftUI
import SwiftData

struct ToggleChipsView: View {
    @Binding var selectedList: String

    private let options = ["Prospects", "Customers"]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                chip(option)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemGroupedBackground))
                .overlay(
                    Capsule()
                        .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    private func chip(_ title: String) -> some View {
        let isSelected = selectedList == title

        return Button {
            ContactScreenHapticsController.shared.lightTap()
            ContactScreenSoundController.shared.playSound1()

            selectedList = title
        } label: {
            Label(title, systemImage: iconName(for: title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(.systemBackground) : Color.clear)
                        .shadow(color: isSelected ? Color.black.opacity(0.08) : .clear, radius: 5, y: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func iconName(for title: String) -> String {
        title == "Prospects" ? "person.crop.circle.badge.plus" : "person.crop.circle.fill"
    }
}
