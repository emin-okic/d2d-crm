//
//  ContactsToolbarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/13/25.
//


import SwiftUI

struct ContactsToolbarView: View {
    @Binding var searchText: String
    @Binding var isSearchExpanded: Bool
    @FocusState<Bool>.Binding var isSearchFocused: Bool

    var onAddTapped: () -> Void

    var body: some View {
        ZStack {
            FloatingNameSearchBar(
                searchText: $searchText,
                isExpanded: $isSearchExpanded,
                isFocused: $isSearchFocused
            )

            if !isSearchExpanded {
                VStack(spacing: 14) {
                    
                    Button(action: onAddTapped) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 4)
                    }
                    
                    Spacer().frame(height: 8) // Small gap before search icon (handled by FloatingNameSearchBar)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.bottom, 100) // Offset to sit above search button
                .padding(.trailing, 20)
                .zIndex(998)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
