//
//  TagPillCompact.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Compact Pill
struct TagPillCompact: View {
    let systemImage: String
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption2)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}
