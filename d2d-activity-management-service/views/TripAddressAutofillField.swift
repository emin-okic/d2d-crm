//
//  TripAddressAutofillField.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/26/26.
//

import SwiftUI
import MapKit

struct TripAddressAutofillField: View {
    let icon: String
    let iconColor: Color
    let placeholder: String

    @Binding var text: String

    let focusedField: FocusState<TripField?>.Binding
    let field: TripField

    @ObservedObject var searchVM: SearchCompleterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)

                TextField(placeholder, text: $text)
                    .focused(focusedField, equals: field)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onChange(of: text) { newValue in
                        searchVM.updateQuery(newValue)
                    }
            }

            if focusedField.wrappedValue == field,
               let suggestion = searchVM.results.first,
               !text.isEmpty {

                Button {
                    SearchBarController.resolveAndSelectAddress(from: suggestion) { resolved in
                        text = resolved
                        focusedField.wrappedValue = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Use suggested address")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(suggestion.title)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
