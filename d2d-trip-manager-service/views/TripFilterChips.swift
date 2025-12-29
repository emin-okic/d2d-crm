//
//  TripFilterChips.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//

import SwiftUI

struct TripFilterChips: View {
    @Binding var selectedFilter: TripFilter
    var onChange: ((TripFilter) -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TripFilter.allCases) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedFilter = option
                        onChange?(option)
                    }
                } label: {
                    Text(option.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedFilter == option ? Color.blue : Color(.secondarySystemBackground))
                        )
                        .foregroundColor(selectedFilter == option ? .white : .primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedFilter == option ? Color.blue.opacity(0.9) : Color.gray.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }
}
