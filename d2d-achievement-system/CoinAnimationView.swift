//
//  CoinAnimationView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/13/25.
//
import SwiftUI

struct CoinAnimationView: View {
    @State var animate: Bool = false

    var body: some View {
       Image(systemName: "circle.fill") // replace with coin asset
          .resizable()
          .frame(width: 24, height: 24)
          .scaleEffect(animate ? 1 : 0)
          .opacity(animate ? 1 : 0)
          .onAppear {
             withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                animate = true
             }
          }
    }
}
