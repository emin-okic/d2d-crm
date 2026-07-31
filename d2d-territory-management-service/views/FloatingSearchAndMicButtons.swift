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
    var isShowingPreviousRegionButton: Bool = false
    var onNavigateToUserLocation: () -> Void = {}
    var onRevertToPreviousRegion: () -> Void = {}
    
    @AppStorage("mapQRCodeWidgetVisible") private var isQRCodeWidgetVisible: Bool = true
    @State private var isEditingWidgets: Bool = false
    @State private var isShowingQRCodeRestoreTarget: Bool = false

    private let floatingButtonSize: CGFloat = 50

    var body: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .bottomTrailing) {
                HStack(alignment: .bottom) {
                    if isExpanded {
                        ExpandableSearchView(
                            searchText: $searchText,
                            isExpanded: $isExpanded,
                            isFocused: $isFocused,
                            viewModel: viewModel,
                            animationNamespace: animationNamespace,
                            onSubmit: onSubmit,
                            onSelectResult: onSelectResult
                        )
                        .frame(maxWidth: 420, alignment: .leading)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    } else {
                        MapScreenToolbarLiquidGlass {
                            VStack(spacing: 10) {
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
                                        .foregroundColor(.white)
                                        .frame(width: floatingButtonSize, height: floatingButtonSize)
                                        .background(Circle().fill(Color.blue))
                                        .shadow(radius: 4)
                                }
                                .transition(.opacity)
                                .accessibilityLabel(
                                    isShowingPreviousRegionButton
                                    ? "Return to Previous Map View"
                                    : "Navigate to Current Location"
                                )

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
                        .onLongPressGesture(minimumDuration: 0.5) {
                            beginWidgetEditing()
                        }
                        .padding(.bottom, 10)
                    }

                    Spacer()
                }
                
                if !isExpanded {
                    qrWidgetSlot
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1000)
                }
            }
            .padding(.leading, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(999)
        .onChange(of: isExpanded) { _, newValue in
            if newValue {
                isEditingWidgets = false
                isShowingQRCodeRestoreTarget = false
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isEditingWidgets)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isQRCodeWidgetVisible)
        .animation(.spring(response: 0.24, dampingFraction: 0.78), value: isShowingQRCodeRestoreTarget)
    }

    @ViewBuilder
    private var qrWidgetSlot: some View {
        if isQRCodeWidgetVisible {
            QRCodeCardView(
                isEditing: isEditingWidgets,
                onBeginEditing: beginWidgetEditing,
                onCancelEditing: cancelWidgetEditing,
                onRemove: removeQRCodeWidget
            )
        } else {
            qrCodeRestoreTarget
                .accessibilityLabel("Add QR Code Widget")
        }
    }

    private var qrCodeRestoreTarget: some View {
        ZStack(alignment: .bottomTrailing) {
            if isShowingQRCodeRestoreTarget {
                qrCodeRestorePrompt
                    .padding(.bottom, 78)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isShowingQRCodeRestoreTarget ? Color.blue.opacity(0.12) : Color.clear)
                .frame(width: 60, height: 60)
                .overlay {
                    if isShowingQRCodeRestoreTarget {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                Color.blue,
                                style: StrokeStyle(lineWidth: 2, dash: [6, 5])
                            )
                    }
                }
                .contentShape(Rectangle())
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            requestQRCodeRestore()
                        }
                )
        }
        .frame(
            width: isShowingQRCodeRestoreTarget ? 260 : 60,
            height: isShowingQRCodeRestoreTarget ? 210 : 60,
            alignment: .bottomTrailing
        )
    }

    private var qrCodeRestorePrompt: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "qrcode")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Restore QR widget")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Add it back to this map shortcut slot.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Button {
                    isShowingQRCodeRestoreTarget = false
                } label: {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button {
                    restoreQRCodeWidget()
                } label: {
                    Text("Add")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(14)
        .frame(width: 248)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
    private func beginWidgetEditing() {
        guard !isExpanded else { return }
        MapScreenHapticsController.shared.lightTap()
        isEditingWidgets = true
    }

    private func cancelWidgetEditing() {
        MapScreenHapticsController.shared.lightTap()
        isEditingWidgets = false
    }

    private func removeQRCodeWidget() {
        MapScreenHapticsController.shared.lightTap()
        isQRCodeWidgetVisible = false
        isEditingWidgets = false
    }

    private func requestQRCodeRestore() {
        guard !isExpanded, !isQRCodeWidgetVisible else { return }
        MapScreenHapticsController.shared.lightTap()
        isShowingQRCodeRestoreTarget = true
    }

    private func restoreQRCodeWidget() {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playPropertyOpen()
        isQRCodeWidgetVisible = true
        isEditingWidgets = false
        isShowingQRCodeRestoreTarget = false
    }
}
