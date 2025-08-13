//
//  FloatingNameSearchBar.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/13/25.
//


import SwiftUI

struct FloatingNameSearchBar: View {
    @Binding var searchText: String
    @Binding var isExpanded: Bool
    @FocusState<Bool>.Binding var isFocused: Bool

    var body: some View {
        VStack {
            if isExpanded {
                HStack {
                    TextField("Search by name...", text: $searchText)
                        .focused($isFocused)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)

                    Button(action: {
                        withAnimation {
                            isExpanded = false
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .shadow(radius: 3)
                .padding(.horizontal)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                Button(action: {
                    withAnimation {
                        isExpanded = true
                        isFocused = true
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }
                .padding(.bottom, 10)
            }
        }
        .padding(.bottom, 30)
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .zIndex(999)
    }
}
