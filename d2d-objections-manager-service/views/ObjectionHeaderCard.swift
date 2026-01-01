//
//  ObjectionHeaderCard.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI

struct ObjectionHeaderCard: View {
    let objection: Objection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(objection.text)
                .font(.title3)
                .fontWeight(.semibold)

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
