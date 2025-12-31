//
//  ContactsToolbarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/13/25.
//

import SwiftUI

struct ContactsToolbarView: View {
    
    var onAddTapped: () -> Void

    var body: some View {
        
        ZStack {
            
            VStack(spacing: 10) {
                Button(action: onAddTapped) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.bottom, 16)
            .padding(.leading, 20)
            .zIndex(998)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
