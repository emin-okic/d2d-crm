//
//  InlineNameSearchBar.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/31/25.
//

import SwiftUI


struct InlineNameSearchBar: View {
    @Binding var searchText: String
    @FocusState<Bool>.Binding var isFocused: Bool
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search by name, address, phone, or email", text: $searchText)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit(onSubmit)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 2, y: 1)
    }
}
