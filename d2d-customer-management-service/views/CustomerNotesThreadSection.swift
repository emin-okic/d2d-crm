//
//  CustomerNotesThreadSection.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/27/25.
//
import SwiftUI
import SwiftData

struct CustomerNotesThreadSection: View {
    @Bindable var customer: Customer
    var maxHeight: CGFloat = 220
    var maxVisibleNotes: Int = 5
    var showChips: Bool = false

    var body: some View {
        VStack {
            if customer.notes.isEmpty {
                Text("No notes yet.").foregroundColor(.secondary)
            } else {
                ForEach(customer.notes.prefix(maxVisibleNotes)) { note in
                    Text(note.content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
