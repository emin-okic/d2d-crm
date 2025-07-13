//
//  RejectionTrackerView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 7/4/25.
//
import SwiftUI

struct RejectionTrackerView: View {
    let count: Int

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: "person.fill.viewfinder")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Knocks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(count)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 4)
        }
        .buttonStyle(.plain)
    }
}
