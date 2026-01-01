//
//  ObjectionMetricCard.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI

struct ObjectionMetricCard<Content: View>: View {
    let title: String
    let value: Int
    let content: Content

    init(
        title: String,
        value: Int,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.value = value
        self.content = content()
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(value)")
                    .font(.title)
                    .fontWeight(.bold)
            }

            Spacer()
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6)
        )
    }
}
