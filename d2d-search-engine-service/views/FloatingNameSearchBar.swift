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
        VStack(spacing: 10) {
            if isExpanded {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search by name...", text: $searchText)
                        .focused($isFocused)
                        .foregroundColor(.primary)
                        .autocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit {
                            withAnimation {
                                isExpanded = false
                            }
                        }

                    Button {
                        withAnimation {
                            isExpanded = false
                            searchText = ""
                            isFocused = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                    .padding(.leading, 4)
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .shadow(radius: 3, x: 0, y: 2)
                .padding(.horizontal)
                .transition(.move(edge: .leading).combined(with: .opacity))

            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded = true
                        isFocused = true
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }
                .padding(.bottom, 10)
            }
        }
        .onChange(of: isExpanded) { expanded in
            if !expanded {
                searchText = ""
                isFocused = false
            }
        }
        .padding(.bottom, 30)
        .padding(.leading, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .zIndex(999)
    }
}
