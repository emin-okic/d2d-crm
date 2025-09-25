//
//  CustomerContainerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/25/25.
//

import SwiftUI

struct CustomerContainerView: View {
    @Binding var selectedList: String
    @Binding var searchText: String

    var body: some View {
        GeometryReader { geo in
            let targetHeight = geo.size.height * 0.90

            NavigationStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    CustomerSectionView(
                        selectedList: $selectedList,
                        containerHeight: targetHeight,
                        searchText: searchText
                    )
                    .padding()
                }
                .frame(height: targetHeight, alignment: .top)
                .frame(maxWidth: .infinity)
                .navigationTitle("Customers")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .frame(maxHeight: .infinity)
    }
}
