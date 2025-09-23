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
        VStack(spacing: 10) {
            Text("Contacts")
                .font(.largeTitle).fontWeight(.bold)
                .padding(.top, 10)

            Text("\(totalProspects) Prospects")
                .font(.title2)
                .foregroundColor(.secondary)

            ProspectProgressBarView(
                current: totalProspects,
                listType: .prospects
            )
            .padding(.horizontal, 20)
        }
    }
}
