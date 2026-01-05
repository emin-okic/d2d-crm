//
//  NoteComposerBarCompact.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Compact Composer
struct NoteComposerBarCompact: View {
    @Binding var text: String
    var placeholder: String
    var onSubmit: () -> Void
    var quickChips: [NoteChip] = []

    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 6) {
            if !quickChips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(quickChips) { chip in
                            Button {
                                if text.isEmpty { text = chip.text }
                                else { text += (text.hasSuffix(" ") ? "" : " ") + chip.text }
                            } label: {
                                Label(chip.label, systemImage: chip.icon)
                                    .font(.caption2)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }

            HStack(spacing: 6) {
                TextField(placeholder, text: $text, axis: .vertical)
                    .focused($focused)
                    .lineLimit(1...3) // compact
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )

                Button(action: onSubmit) {
                    Image(systemName: "paperplane.fill").imageScale(.medium).padding(8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
