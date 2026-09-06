//
//  QRCodeCardView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//
import SwiftUI
import CoreImage.CIFilterBuiltins


struct QRCodeCardView: View {
    @State private var qrURL: String = "https://example.com"
    @State private var showQRCodeSheet: Bool = false
    @State private var qrSheetDetent: PresentationDetent = .fraction(0.58)

    var isEditing: Bool = false
    var controlSize: CGFloat = 60
    var onBeginEditing: () -> Void = {}
    var onCancelEditing: () -> Void = {}
    var onRemove: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isEditing {
                removePrompt
                    .padding(.bottom, 78)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            qrButton
        }
        .frame(
            width: isEditing ? 260 : controlSize,
            height: isEditing ? 210 : controlSize,
            alignment: .bottomTrailing
        )
        .sheet(isPresented: $showQRCodeSheet) {
            QRCodeDetailView(qrURL: $qrURL, sheetDetent: $qrSheetDetent)
                .presentationDetents([.fraction(0.58), .fraction(0.76)], selection: $qrSheetDetent)
                .presentationDragIndicator(.visible)
        }
    }

    private var qrButton: some View {
        Button(action: {
            guard !isEditing else { return }
            
            // ✅ Haptics
            MapScreenHapticsController.shared.lightTap()
            
            // ✅ Sound
            MapScreenSoundController.shared.playPropertyOpen()
            
            showQRCodeSheet = true
        }) {
            VStack {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: controlSize * 0.52, height: controlSize * 0.52)
                    .foregroundColor(.blue)
            }
            .frame(width: controlSize, height: controlSize)
            .background(Color(.systemBackground).opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if isEditing {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            Color.red,
                            style: StrokeStyle(lineWidth: 2, dash: [6, 5])
                        )
                }
            }
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onBeginEditing()
                }
        )
    }

    private var removePrompt: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(width: 36, height: 36)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Remove QR widget")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Hide this shortcut from the map. You can add it back later.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Button {
                    onCancelEditing()
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
                    onRemove()
                } label: {
                    Text("Remove")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .background(Color.red, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
}
