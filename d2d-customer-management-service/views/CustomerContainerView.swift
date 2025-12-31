//
//  CustomerContainerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//

import SwiftUI

struct CustomerContainerView: View {
    @Binding var searchText: String
    
    @FocusState<Bool>.Binding var isSearchFocused: Bool
    
    @Binding var selectedCustomer: Customer?

    var body: some View {
        GeometryReader { geo in
            let targetHeight = geo.size.height * 0.90

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                CustomersSectionView(
                    searchText: $searchText,
                    isSearchFocused: $isSearchFocused,
                    selectedCustomer: $selectedCustomer
                )
                    .padding()
            }
            .frame(height: targetHeight, alignment: .top)
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity)
    }
}
