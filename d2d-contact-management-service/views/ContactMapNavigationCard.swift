//
//  ContactMapNavigationCard.swift
//  d2d-studio
//
//  Created by Codex on 8/25/26.
//

import SwiftUI

struct ContactMapNavigationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "location.fill.viewfinder")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 38, height: 38)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Contact On Map")
    }
}
