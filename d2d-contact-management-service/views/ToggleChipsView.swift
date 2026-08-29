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
    var horizontalPadding: CGFloat = 20

    var body: some View {
        HStack(spacing: 6) {
            chip("Prospects")
            chip("Customers")
        }
        .padding(.horizontal, horizontalPadding)
    }

    private func chip(_ title: String) -> some View {
        
        Button {
            
            // ✅ Haptics & Sound when selecting a pill
            ContactScreenHapticsController.shared.lightTap()
            ContactScreenSoundController.shared.playSound1()
            
            selectedList = title
        } label: {
            Label(title, systemImage: title == "Prospects" ? "person.2.fill" : "checkmark.seal.fill")
                .font(.callout.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .foregroundColor(selectedList == title ? .white : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(minWidth: 112)
                .frame(height: 50)
                .background(chipBackground(isSelected: selectedList == title))
        }
        .buttonStyle(.plain)
    }

    private func chipBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(isSelected ? Color.blue : Color(.secondarySystemBackground).opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.20 : 0.10), lineWidth: 1)
            )
    }
}
