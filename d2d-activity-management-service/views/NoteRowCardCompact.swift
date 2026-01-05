//
//  NoteRowCardCompact.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import SwiftUI
import SwiftData
import UIKit

struct NoteRowCardCompact: View {
    let authorInitials: String
    let content: String
    let date: Date
    let accent: NoteAccent?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Small avatar
            ZStack {
                Circle().fill(Color(.systemGray5)).frame(width: 24, height: 24)
                Text(initials(authorInitials)).font(.caption2).bold()
            }

            // Slim card
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("You").font(.footnote).fontWeight(.semibold)
                    Text("·").foregroundColor(.secondary)
                    Text(relative(date)).font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    if let accent {
                        TagPillCompact(systemImage: accent.systemImage, text: accent.text)
                    }
                }

                Text(attributed(content))
                    .font(.subheadline) // smaller
                    .foregroundStyle(.primary)
                    .lineLimit(3)       // ⬅️ keep rows tidy
                    .textSelection(.enabled)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private func initials(_ text: String) -> String {
        let parts = text.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)) }
        return String(text.prefix(2)).uppercased()
    }

    private func relative(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }

    private func attributed(_ string: String) -> AttributedString {
        var out = AttributedString(string)

        // keywords
        let highlights = ["follow up", "follow-up", "converted", "sale", "wasn't home", "no answer"]
        for key in highlights {
            var cursor = out.startIndex
            while let r = out[cursor...].range(of: key, options: .caseInsensitive) {
                out[r].font = .subheadline.bold()
                cursor = r.upperBound
            }
        }

        // simple tokens
        let tokens = ["am","pm","AM","PM","Mon","Tue","Wed","Thu","Fri","Sat","Sun",
                      "January","February","March","April","May","June","July","August",
                      "September","October","November","December"]
        for t in tokens {
            var cursor = out.startIndex
            while let r = out[cursor...].range(of: t, options: .caseInsensitive) {
                out[r].font = .subheadline.bold()
                cursor = r.upperBound
            }
        }

        return out
    }
}
