//
//  FloatingSearchButtonView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/3/25.
//

import SwiftUI
import MapKit

struct FloatingSearchButtonView: View {
    @Binding var searchText: String
    @Binding var isSearchExpanded: Bool
    @FocusState.Binding var isSearchFocused: Bool
    var viewModel: SearchCompleterViewModel
    var namespace: Namespace.ID

    var onSubmit: () -> Void
    var onSelectResult: (MKLocalSearchCompletion) -> Void
    var onCancel: () -> Void
    var onClearFocus: () -> Void = {}

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if isSearchExpanded {
                    SearchBarView(
                        searchText: $searchText,
                        isFocused: $isSearchFocused,
                        viewModel: viewModel,
                        onSubmit: {
                            onSubmit()
                            withAnimation { isSearchExpanded = false }
                        },
                        onSelectResult: {
                            onSelectResult($0)
                            onClearFocus()
                        },
                        onCancel: {
                            withAnimation {
                                isSearchExpanded = false
                                searchText = ""
                            }
                            onCancel()
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                    .matchedGeometryEffect(id: "search", in: namespace)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSearchExpanded = true
                            isSearchFocused = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.blue))
                    }
                    .matchedGeometryEffect(id: "search", in: namespace)
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                    .shadow(radius: 4)
                }
            }
        }
    }
}
