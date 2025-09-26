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

    var body: some View {
        HStack(spacing: 10) {
            chip("Prospects")
            chip("Customers")
        }
        .padding(.horizontal, 20)
    }

    private func chip(_ title: String) -> some View {
        Button {
            selectedList = title
        } label: {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .frame(minWidth: 110)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedList == title ? Color.blue : Color(.secondarySystemBackground))
                )
                .foregroundColor(selectedList == title ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
