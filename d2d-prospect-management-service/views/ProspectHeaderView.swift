//
//  ProspectHeaderView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import SwiftUI

struct ProspectHeaderView: View {
    let totalProspects: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("Contacts")
                .font(.title.weight(.bold))
                .padding(.top, 6)

            ProspectProgressBarView(
                current: totalProspects,
                listType: .prospects
            )
            .padding(.horizontal, 20)
        }
    }
}
