//
//  SearchSuggestionsListView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import SwiftUI
import MapKit

struct SearchSuggestionsListView: View {
    var isVisible: Bool
    var results: [MKLocalSearchCompletion]
    var onSelect: (MKLocalSearchCompletion) -> Void

    var body: some View {
        if isVisible && !results.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text("Suggested properties")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    Text("\(min(results.count, 5))")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.blue)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(Color.blue.opacity(0.12), in: Capsule())
                }
                .padding(.horizontal, 12)
                .padding(.top, 11)
                .padding(.bottom, 7)

                ForEach(Array(results.prefix(5).enumerated()), id: \.element) { index, result in
                    suggestionButton(for: result)

                    if index < min(results.count, 5) - 1 {
                        Divider()
                            .padding(.leading, 58)
                    }
                }
            }
            .background(Color(.systemBackground).opacity(0.94), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, maxHeight: 288)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(10)
        }
    }

    private func suggestionButton(for result: MKLocalSearchCompletion) -> some View {
        Button {
            onSelect(result)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(result.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(result.subtitle.isEmpty ? "Address match" : result.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Property")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(.secondarySystemBackground), in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
