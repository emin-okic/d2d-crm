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
        GeometryReader { geo in
            // target is ~75% of the available height in this screen
            let targetHeight = geo.size.height * 0.90

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // Pass the resolved height down so the table area can size itself
                ProspectsSectionView(selectedList: $selectedList, containerHeight: targetHeight)
                    .padding()
            }
            .frame(height: targetHeight, alignment: .top)
            .frame(maxWidth: .infinity)
        }
        // Let the reader expand to the screen (RolodexView already has Spacer below)
        .frame(maxHeight: .infinity)
    }
}
