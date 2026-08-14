//
//  CustomerFilterRow.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/31/25.
//

import SwiftUI

struct CustomerFilterRow: View {
    @Binding var searchText: String
    @Binding var selectedField: ContactSearchField
    @FocusState<Bool>.Binding var isSearchFocused: Bool
    var onSubmit: () -> Void
    var onClear: () -> Void

    var body: some View {
        HStack {
            Spacer()

            SearchFilterPill(
                searchText: $searchText,
                selectedField: $selectedField,
                isFocused: $isSearchFocused,
                onSubmit: onSubmit,
                onClear: onClear
            )

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}
