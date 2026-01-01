//
//  RankBadge.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI

struct RankBadge: View {
    let rank: Int

    private var color: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }

    var body: some View {
        Text("#\(rank)")
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(8)
            .background(Circle().fill(color))
            .shadow(radius: 2)
    }
}
