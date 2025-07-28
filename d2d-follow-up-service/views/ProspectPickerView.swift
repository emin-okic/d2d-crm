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
        List {
            ForEach(prospects) { prospect in
                Button {
                    onSelect(prospect)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(prospect.fullName)
                            .font(.body)
                        Text(prospect.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 10)                // extra vertical padding
                }
            }
        }
        .listStyle(InsetGroupedListStyle())               // inset style for more breathing room
        .navigationTitle("Schedule Follow Up")            // clearer, action-oriented title
    }
}
