//
//  RecentSearchesView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI

struct RecentSearchesView: View {
    let recentSearches: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(recentSearches, id: \.self) { query in
                    Button(action: {
                        onSelect(query)
                    }) {
                        Text(query)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 180)
        .padding(.top, 8)
    }
}
