//
//  ProspectPickerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI
import SwiftData

struct ProspectPickerView: View {
    let prospects: [Prospect]
    @Binding var selectedProspect: Prospect?
    @Environment(\.dismiss) private var dismiss
    var title: String = "Pick Prospect"

    var body: some View {
        NavigationStack {
            List(prospects) { prospect in
                Button {
                    selectedProspect = prospect
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prospect.fullName)
                            .font(.body)
                        Text(prospect.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle(title)
            .listStyle(.plain)
        }
    }
}
