//
//  FloatingSearchAndMicButtons.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/6/25.
//


import SwiftUI
import MapKit

struct FloatingSearchAndMicButtons: View {
    @Binding var searchText: String
    @Binding var isExpanded: Bool
    @FocusState<Bool>.Binding var isFocused: Bool

    var viewModel: SearchCompleterViewModel
    var animationNamespace: Namespace.ID
    var onSubmit: () -> Void
    var onSelectResult: (MKLocalSearchCompletion) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ExpandableSearchView(
                searchText: $searchText,
                isExpanded: $isExpanded,
                isFocused: $isFocused,
                viewModel: viewModel,
                animationNamespace: animationNamespace,
                onSubmit: onSubmit,
                onSelectResult: onSelectResult
            )

            if !isExpanded {
                RecordingToggleButton()
                    .transition(.opacity)
                    .padding(.bottom, 10)
            }
        }
        .padding(.bottom, 30)
        .padding(.leading, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .zIndex(999)
    }
}
