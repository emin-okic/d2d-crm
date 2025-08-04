//
//  ExpandableSearchView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//

import SwiftUI
import MapKit

struct ExpandableSearchView: View {
    @Binding var searchText: String
    @Binding var isExpanded: Bool
    @FocusState.Binding var isFocused: Bool

    @ObservedObject var viewModel: SearchCompleterViewModel

    var animationNamespace: Namespace.ID
    var onSubmit: () -> Void
    var onSelectResult: (MKLocalSearchCompletion) -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if isExpanded {
                    SearchBarView(
                        searchText: $searchText,
                        isFocused: $isFocused,
                        viewModel: viewModel,
                        onSubmit: {
                            onSubmit()
                            searchText = ""
                            withAnimation { isExpanded = false }
                        },
                        onSelectResult: {
                            onSelectResult($0)
                        },
                        onCancel: {
                            withAnimation {
                                isExpanded = false
                                searchText = ""
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                    .matchedGeometryEffect(id: "search", in: animationNamespace)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
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
                    }
                    .matchedGeometryEffect(id: "search", in: animationNamespace)
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                    .shadow(radius: 4)
                }
            }
        }
    }
}
