//
//  ProspectPickerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/13/25.
//
import SwiftUI
import SwiftData

struct ProspectPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Query private var prospects: [Prospect]
    let onSelect: (Prospect) -> Void

    var body: some View {
        List(prospects) { prospect in
            Button {
                onSelect(prospect)
                dismiss()
            } label: {
                VStack(alignment: .leading) {
                    Text(prospect.fullName)
                    Text(prospect.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Choose Prospect")
    }
}
