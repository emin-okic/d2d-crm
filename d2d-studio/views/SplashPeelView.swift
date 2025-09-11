//
//  SplashPeelView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/11/25.
//

import SwiftUI

struct SplashPeelView: View {
    @State private var revealStep: Int = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    
    @State private var scale: CGFloat = 0.6
    @State private var opacity = 0.0
    @State private var offsetY: CGFloat = 0

    // Total number of peel rows (more = smoother)
    private let rowCount = 20

    var body: some View {
        ZStack {
            // Underneath: white background and D2D logo
            Color.white.ignoresSafeArea()

            Image("SplashIcon") // Make sure "AppIcon" is added to Assets.xcassets
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .scaleEffect(scale)
                .opacity(opacity)
                .offset(y: offsetY)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.0)) {
                        self.scale = 1.0
                        self.opacity = 1.0
                    }
                    withAnimation(.easeInOut(duration: 0.6).delay(1.2)) {
                        self.offsetY = -300
                        self.opacity = 0.0
                    }
                }

            // Over: black peel rows
            VStack(spacing: 0) {
                ForEach(0..<rowCount, id: \.self) { i in
                    Rectangle()
                        .fill(Color.black)
                        .frame(maxWidth: .infinity)
                        .opacity(i < revealStep ? 0 : 1)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            // Animate row peeling one-by-one
            for i in 0..<rowCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        revealStep = i + 1
                    }
                }
            }

            // Logo animation (starts mid-peel)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
            }
        }
    }
}
