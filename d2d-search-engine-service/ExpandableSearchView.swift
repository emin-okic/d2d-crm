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
    
    private let floatingButtonSize: CGFloat = 50

    var body: some View {
        VStack {
            
            HStack {

                if isExpanded {
                    
                    SearchBarView(
                        searchText: $searchText,
                        isFocused: $isFocused,
                        viewModel: viewModel,
                        onSubmit: {
                            onSubmit()
                            resetSearchState()
                            withAnimation { isExpanded = false }
                        },
                        onSelectResult: {
                            onSelectResult($0)
                            resetSearchState()
                            
                            // Collapse search bar
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                                isFocused = false
                            }
                        },
                        onCancel: {
                            resetSearchState()
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .matchedGeometryEffect(id: "search", in: animationNamespace)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    Button {
                        
                        // ✅ Haptics
                        MapScreenHapticsController.shared.lightTap()
                        
                        // ✅ Sound
                        MapScreenSoundController.shared.playPropertyOpen()
                        
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isExpanded = true
                            isFocused = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: floatingButtonSize, height: floatingButtonSize)
                            .background(Circle().fill(Color.blue))
                    }
                    .matchedGeometryEffect(id: "search", in: animationNamespace)
                    .shadow(radius: 4)
                }
            }
        }
    }

    private func resetSearchState() {
        searchText = ""
        viewModel.clear()
    }
}
