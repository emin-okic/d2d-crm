//
//  SearchSuggestionsListView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import SwiftUI
import MapKit

struct SearchSuggestionsListView: View {
    var isVisible: Bool
    var results: [MKLocalSearchCompletion]
    var onSelect: (MKLocalSearchCompletion) -> Void

    var body: some View {
        if isVisible && !results.isEmpty {
            VStack(spacing: 0) {
                ForEach(results.prefix(3), id: \.self) { result in
                    Button {
                        onSelect(result)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title)
                                .font(.body)
                                .bold()
                                .lineLimit(1)

                            Text(result.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 4)
            .shadow(radius: 4)
            .frame(maxWidth: .infinity, maxHeight: 180)
            .transition(.opacity)
            .zIndex(10)
        }
    }
}
