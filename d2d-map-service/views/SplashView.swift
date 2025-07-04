//
//  SplashView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 7/4/25.
//
import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity = 0.0
    @State private var offsetY: CGFloat = 0

    var body: some View {
        ZStack {
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
        }
    }
}
