//
//  LeaderboardCard.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/8/25.
//
import Foundation
import SwiftData
import SwiftUICore

struct LeaderboardCardView: View {
    let title: String
    let count: Int

    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("\(count)")
                .font(.title)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
