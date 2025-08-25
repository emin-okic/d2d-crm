//
//  ContactsContainerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/25/25.
//

import SwiftUI

struct ContactsContainerView: View {
    @Binding var selectedList: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            ProspectsSectionView(selectedList: $selectedList)
                .padding()
        }
        .frame(height: 400) // ~3 rows + padding (tweak if you want)
    }
}
