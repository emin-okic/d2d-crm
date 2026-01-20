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
    
    var userLocationManager: UserLocationManager
    var mapController: MapController
    
    private let floatingButtonSize: CGFloat = 50

    var body: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .bottomTrailing) {
                // 🔹 Toolbar glass + search
                HStack {
                    MapScreenToolbarLiquidGlass {
                        VStack(spacing: 10) {

                            if !isExpanded {
                                Button {
                                    MapScreenHapticsController.shared.lightTap()
                                    MapScreenSoundController.shared.playPropertyOpen()
                                    if let loc = userLocationManager.location {
                                        mapController.region.center = loc.coordinate
                                    }
                                } label: {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.white)
                                        .frame(width: floatingButtonSize, height: floatingButtonSize)
                                        .background(Circle().fill(Color.blue))
                                        .shadow(radius: 4)
                                }
                                .transition(.opacity)
                            }

                            ExpandableSearchView(
                                searchText: $searchText,
                                isExpanded: $isExpanded,
                                isFocused: $isFocused,
                                viewModel: viewModel,
                                animationNamespace: animationNamespace,
                                onSubmit: onSubmit,
                                onSelectResult: onSelectResult
                            )
                        }
                    }
                    .padding(.bottom, 10)

                    Spacer()
                }
                
                // 🔹 Floating QR code button, aligned to bottom of search button
                if !isExpanded {
                    QRCodeCardView()
                        .padding(.trailing, 20)
                        .padding(.bottom, 20) // same bottom padding as toolbar glass
                        .transition(.opacity)
                        .zIndex(1000)
                }
            }
            .padding(.leading, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(999)
    }
}
