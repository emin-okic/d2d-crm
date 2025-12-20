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
    
    // For the center on my location button
    var userLocationManager: UserLocationManager
    var mapController: MapController

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
                VStack(spacing: 10) {
                    Button {
                        if let loc = userLocationManager.location {
                            mapController.region.center = loc.coordinate
                        }
                    } label: {
                        Image(systemName: "location.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    Circle().fill(Color.blue)
                                )
                                .shadow(radius: 4)
                    }

                    // RecordingToggleButton()
                }
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
