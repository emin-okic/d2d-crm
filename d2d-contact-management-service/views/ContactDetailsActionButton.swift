//
//  CRMActionButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//

import SwiftUI

/// A modern CRM-style action button used in ProspectActionsToolbar
struct ContactDetailsActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(4)
        }
        .buttonStyle(.plain)
        .shadow(color: color.opacity(0.25), radius: 4, x: 0, y: 2)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: UUID())
    }
}

#Preview {
    ContactDetailsActionButton(icon: "phone.fill", title: "Call", color: .blue) {
        print("Call tapped")
    }
}

