//
//  SavedResponsesList.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI

struct SavedResponsesList: View {
    let responses: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Practice Responses")
                .font(.headline)

            ForEach(responses, id: \.self) { response in
                Text(response)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
        }
    }
}
