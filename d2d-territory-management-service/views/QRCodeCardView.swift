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
    
    var body: some View {
        VStack {
            Button(action: {
                
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
        }
        .sheet(isPresented: $showQRCodeSheet) {
            QRCodeDetailView(qrURL: $qrURL)
                .presentationDetents([.fraction(0.5)]) // 50% of screen height
                .presentationDragIndicator(.visible)  
        }
    }
}
