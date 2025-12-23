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
            
            // 🔹 Tap-outside dismiss layer
            if isSearchExpanded {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isSearchExpanded = false
                        }
                    }
                    .zIndex(1)
            }
            
            FloatingNameSearchBar(
                searchText: $searchText,
                isExpanded: $isSearchExpanded,
                isFocused: $isSearchFocused
            )

            if !isSearchExpanded {
                VStack(spacing: 10) {
                    Button(action: onAddTapped) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 4)
                    }
                    
                    // Spacer().frame(height: 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.bottom, 110)
                .padding(.leading, 20)
                .zIndex(998)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
