//
//  SuggestedProspectBannerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/17/25.
//

import SwiftUI

struct SuggestedProspectBannerView: View {
    
    let suggestion: Prospect
    var onAdd: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested Neighbor")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(suggestion.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            // Buttons vertical
            VStack(spacing: 12) {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
