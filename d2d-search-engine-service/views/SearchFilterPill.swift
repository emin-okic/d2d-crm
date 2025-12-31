//
//  SearchFilterPill.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/31/25.
//
import SwiftUI

struct SearchFilterPill: View {
    @Binding var searchText: String
    @FocusState<Bool>.Binding var isFocused: Bool
    var onSubmit: () -> Void   // 👈 ADD

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("Search", text: $searchText)
                .focused($isFocused)
                .font(.subheadline)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit()
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}
