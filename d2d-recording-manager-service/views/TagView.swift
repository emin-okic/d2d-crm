//
//  TagView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/6/26.
//

import SwiftUI

struct TagView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
