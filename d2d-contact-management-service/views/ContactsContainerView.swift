//
//  ContactsContainerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/25/25.
//

import SwiftUI

struct ContactsContainerView: View {
    
    @Binding var selectedList: String
    @Binding var searchText: String
    
    @Binding var isSearchExpanded: Bool
    @FocusState<Bool>.Binding var isSearchFocused: Bool
    
    @Binding var selectedProspect: Prospect?

    var body: some View {
        GeometryReader { geo in
            let targetHeight = geo.size.height * 0.90

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                ProspectsSectionView(
                    selectedList: $selectedList,
                    selectedProspect: $selectedProspect,
                    containerHeight: targetHeight,
                    searchText: $searchText,
                    isSearchExpanded: $isSearchExpanded,
                    isSearchFocused: $isSearchFocused
                )
                .padding()
            }
            .frame(height: targetHeight, alignment: .top)
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity)
    }
}
