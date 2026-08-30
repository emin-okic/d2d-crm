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
    @Binding var contactSearchText: String
    @Binding var selectedContactSearchField: ContactSearchField
    @Binding var searchMode: MapSearchMode
    @Binding var isExpanded: Bool
    @FocusState<Bool>.Binding var isFocused: Bool

    var viewModel: SearchCompleterViewModel
    var animationNamespace: Namespace.ID
    var onSubmit: () -> Void
    var onSubmitContactFilter: () -> Void
    var onClearContactFilter: () -> Void
    var onSelectResult: (MKLocalSearchCompletion) -> Void
    
    var userLocationManager: UserLocationManager
    var mapController: MapController
    var isShowingPreviousRegionButton: Bool = false
    var onNavigateToUserLocation: () -> Void = {}
    var onRevertToPreviousRegion: () -> Void = {}

    @State private var qrURL: String = "https://example.com"
    @State private var isShowingQRCodeSheet: Bool = false
    @State private var qrSheetDetent: PresentationDetent = .fraction(0.58)

    private let controlButtonSize: CGFloat = 48

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                if isExpanded {
                    ExpandableSearchView(
                        searchText: $searchText,
                        contactSearchText: $contactSearchText,
                        selectedContactSearchField: $selectedContactSearchField,
                        searchMode: $searchMode,
                        isExpanded: $isExpanded,
                        isFocused: $isFocused,
                        viewModel: viewModel,
                        animationNamespace: animationNamespace,
                        onSubmit: onSubmit,
                        onSubmitContactFilter: onSubmitContactFilter,
                        onClearContactFilter: onClearContactFilter,
                        onSelectResult: onSelectResult
                    )
                    .padding(.horizontal, 14)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    HStack(alignment: .bottom) {
                        bottomLeftToolbar

                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    bottomSearchBar
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(999)
        .sheet(isPresented: $isShowingQRCodeSheet) {
            QRCodeDetailView(qrURL: $qrURL, sheetDetent: $qrSheetDetent)
                .presentationDetents([.fraction(0.58), .fraction(0.76)], selection: $qrSheetDetent)
                .presentationDragIndicator(.visible)
        }
    }

    private var bottomLeftToolbar: some View {
        VStack(spacing: 0) {
            locationButton

            Divider()
                .padding(.horizontal, 8)

            qrCodeButton
        }
        .frame(width: 50)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(Color.white.opacity(0.38), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 14, x: 0, y: 7)
        .transition(.scale.combined(with: .opacity))
    }

    private var locationButton: some View {
        Button {
            MapScreenHapticsController.shared.lightTap()
            MapScreenSoundController.shared.playPropertyOpen()
            if isShowingPreviousRegionButton {
                onRevertToPreviousRegion()
            } else {
                onNavigateToUserLocation()
            }
        } label: {
            Image(systemName: isShowingPreviousRegionButton ? "arrow.uturn.backward" : "location.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.blue)
                .frame(width: controlButtonSize, height: controlButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isShowingPreviousRegionButton
            ? "Return to Previous Map View"
            : "Navigate to Current Location"
        )
    }

    private var qrCodeButton: some View {
        Button {
            MapScreenHapticsController.shared.lightTap()
            MapScreenSoundController.shared.playPropertyOpen()
            isShowingQRCodeSheet = true
        } label: {
            Image(systemName: "qrcode")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: controlButtonSize, height: controlButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show QR Code")
    }

    private var bottomSearchBar: some View {
        Button {
            openSearch()
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Search Maps")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 17)
            .frame(height: 52)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.38), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 8)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .matchedGeometryEffect(id: "search", in: animationNamespace)
        .accessibilityLabel("Search map")
    }

    private func openSearch() {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playPropertyOpen()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
            isExpanded = true
            isFocused = true
        }
    }
}
