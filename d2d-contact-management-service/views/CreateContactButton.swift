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
            ContactDetailsHapticsController.shared.lightTap()
            ContactScreenSoundController.shared.playSound1()
            
            action()
            
        } label: {
            
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.blue))
                .shadow(radius: 4)

        }
        
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
