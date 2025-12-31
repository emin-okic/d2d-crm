//
//  ProspectFilterRow.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/31/25.
//

import SwiftUI

struct ProspectFilterRow: View {
    @Binding var searchText: String
    @FocusState<Bool>.Binding var isSearchFocused: Bool
    var onSubmit: () -> Void

    var body: some View {
        HStack {
            Spacer()

            SearchFilterPill(
                searchText: $searchText,
                isFocused: $isSearchFocused,
                onSubmit: onSubmit
            )

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}
