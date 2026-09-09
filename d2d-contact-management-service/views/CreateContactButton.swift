//
//  CreateContactButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/4/26.
//

import SwiftUI

struct CreateContactButton: View {
    
    var action: () -> Void
    
    var body: some View {
        Button {
            
            // Haptics + sound
            ContactScreenHapticsController.shared.lightTap()
            ContactScreenSoundController.shared.playSound1()
            
            action()
            
        } label: {
            
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 46, height: 46)

        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add Contact")
    }
}

struct CreateContactButton_Previews: PreviewProvider {
    static var previews: some View {
        CreateContactButton {
            print("Add tapped")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
