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

    var isEditing: Bool = false
    var onBeginEditing: () -> Void = {}
    var onRemove: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .topLeading) {
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
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(width: 60, height: 60)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        onBeginEditing()
                    }
            )
            .contextMenu {
                Button {
                    onRemove()
                } label: {
                    Label("Remove QR Code Widget", systemImage: "minus.circle")
                }
            }

            if isEditing {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.red, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.85), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .offset(x: -8, y: -8)
                .accessibilityLabel("Remove QR Code Widget")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showQRCodeSheet) {
            QRCodeDetailView(qrURL: $qrURL)
                .presentationDetents([.fraction(0.5)]) // 50% of screen height
                .presentationDragIndicator(.visible)  
        }
    }
}
