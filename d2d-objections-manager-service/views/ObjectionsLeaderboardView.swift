//
//  ObjectionsLeaderboardView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI

struct ObjectionsLeaderboardView: View {
    let ranked: [RankedObjection]
    let isEditing: Bool
    let selected: Set<Objection>
    let onSelect: (Objection) -> Void

    private let maximumVisibleObjections = 5
    private let rowHeight: CGFloat = 68
    private let rowSpacing: CGFloat = 12

    var body: some View {
        if ranked.count > maximumVisibleObjections {
            ScrollView {
                leaderboard
            }
            .frame(height: maximumListHeight)
        } else {
            leaderboard
        }
    }

    private var maximumListHeight: CGFloat {
        (rowHeight * CGFloat(maximumVisibleObjections))
            + (rowSpacing * CGFloat(maximumVisibleObjections - 1))
    }

    private var leaderboard: some View {
        LazyVStack(spacing: rowSpacing) {
            ForEach(ranked) { item in
                ObjectionLeaderboardCard(
                    ranked: item,
                    isSelected: selected.contains(item.objection),
                    isEditing: isEditing
                ) {
                    onSelect(item.objection)
                }
                .frame(minHeight: rowHeight)
            }
        }
        .padding(.horizontal)
    }
}
