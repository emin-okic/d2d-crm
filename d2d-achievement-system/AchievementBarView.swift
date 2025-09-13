//
//  AchievementBarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/13/25.
//
import SwiftUI

struct AchievementBarView: View {
    var progress: Int
    var goal: Int
    
    var isCompleted: Bool = false

    var body: some View {
        VStack {
            
           HStack(spacing: 8) {
              Text("First \(goal) Prospects")
                 .font(.headline)
              Spacer()
              Text("\(progress)/\(goal)")
                 .font(.subheadline)
           }
            
           ProgressView(value: Double(progress), total: Double(goal))
              .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .transition(.scale)
                }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
        .padding(.top, 20)
    }
}
