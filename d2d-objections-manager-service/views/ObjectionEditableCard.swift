//
//  ObjectionEditableCard.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/1/26.
//

import SwiftUI

struct ObjectionEditableCard: View {
    let title: String
    let subtitle: String
    @Binding var text: String
    var isMultiline: Bool = false
    var trailingAction: AnyView?

    init(
        title: String,
        subtitle: String,
        text: Binding<String>,
        isMultiline: Bool = false,
        trailingAction: (() -> AnyView)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self._text = text
        self.isMultiline = isMultiline
        self.trailingAction = trailingAction?()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                trailingAction
            }

            if isMultiline {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden) // 🔥 removes system gray
                        .padding(12)
                        .frame(minHeight: 140)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        )
                        .cornerRadius(12)

                    // Optional placeholder (CRM polish)
                    if text.isEmpty {
                        Text("Write your recommended response here…")
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.top, 20)
                            .padding(.leading, 18)
                    }
                }
            } else {
                TextField("", text: $text)
                    .textFieldStyle(.roundedBorder)
            }
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }
}
