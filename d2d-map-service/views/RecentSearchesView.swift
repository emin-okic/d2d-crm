//
//  RecentSearchesView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI

struct RecentSearchesView: View {
    let recentProspectIDs: [UUID]
    let allProspects: [Prospect]
    let onSelect: (Prospect) -> Void

    var body: some View {
        let recentProspects = recentProspectIDs.compactMap { id in
            allProspects.first(where: { $0.id == id })
        }

        ScrollView {
            VStack(spacing: 8) {
                ForEach(recentProspects, id: \.id) { prospect in
                    Button(action: {
                        onSelect(prospect)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prospect.fullName)
                                .font(.headline)
                            Text(prospect.address)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
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
