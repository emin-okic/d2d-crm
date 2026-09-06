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
    
    @AppStorage("mapQRCodeWidgetVisible") private var isQRCodeWidgetVisible: Bool = true
    @State private var isEditingWidgets: Bool = false
    @State private var isShowingQRCodeRestoreTarget: Bool = false

    private let floatingControlSize: CGFloat = 44

    var body: some View {
        VStack {
            Spacer()

            ZStack(alignment: .bottomTrailing) {
                searchTray
                    .frame(maxWidth: 500, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !isExpanded {
                    floatingControlCluster
                        .padding(.trailing, 16)
                        .padding(.bottom, 88)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1000)
                }
            }
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

    private var searchTray: some View {
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
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var floatingControlCluster: some View {
        VStack(spacing: 0) {
            qrWidgetSlot

            Divider()
                .frame(width: 26)
                .padding(.vertical, 2)

            locationControlButton
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.24), radius: 14, x: 0, y: 7)
    }

    private var locationControlButton: some View {
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
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: floatingControlSize, height: floatingControlSize)
                .background(Color(.systemBackground).opacity(0.88), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isShowingPreviousRegionButton
            ? "Return to Previous Map View"
            : "Navigate to Current Location"
        )
    }

    @ViewBuilder
    private var qrWidgetSlot: some View {
        if isQRCodeWidgetVisible {
            QRCodeCardView(
                isEditing: isEditingWidgets,
                controlSize: floatingControlSize,
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
                .frame(width: floatingControlSize, height: floatingControlSize)
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
            width: isShowingQRCodeRestoreTarget ? 260 : floatingControlSize,
            height: isShowingQRCodeRestoreTarget ? 210 : floatingControlSize,
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
