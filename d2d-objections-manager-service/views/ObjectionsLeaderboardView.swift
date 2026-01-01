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

    var body: some View {
        VStack(spacing: 12) {
            ForEach(ranked) { item in
                ObjectionLeaderboardCard(
                    ranked: item,
                    isSelected: selected.contains(item.objection),
                    isEditing: isEditing
                ) {
                    onSelect(item.objection)
                }
            }
        }
        .padding(.horizontal)
    }
}
