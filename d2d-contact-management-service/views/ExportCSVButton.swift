//
//  ExportCSVButton.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/2/26.
//

import SwiftUI

struct ExportCSVButton: View {

    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "square.and.arrow.up")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .foregroundColor(.blue)
                .padding()
                .frame(width: 60, height: 60)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 2)
        }
    }
}
