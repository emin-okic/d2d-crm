//
//  ConfettiBurstView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/8/25.
//

import SwiftUI

struct ConfettiBurstView: View {
    @State private var anim = false
    private let emojis = ["🎉","✨","🎊","⭐️","💫"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<24, id: \.self) { _ in
                    let x = CGFloat.random(in: 0...geo.size.width)
                    let y = CGFloat.random(in: geo.size.height * 0.3 ... geo.size.height * 0.6)
                    Text(emojis.randomElement()!)
                        .font(.system(size: CGFloat.random(in: 16...26)))
                        .position(x: x, y: y)
                        .offset(y: anim ? 500 : 0)
                        .rotationEffect(.degrees(anim ? Double.random(in: -180...180) : 0))
                        .opacity(anim ? 0 : 1)
                        .animation(.easeOut(duration: Double.random(in: 1.0...1.6)), value: anim)
                }
            }
            .ignoresSafeArea()
            .onAppear { anim = true }
        }
        .allowsHitTesting(false)
    }
}
