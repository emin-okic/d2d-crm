//
//  AddressAutocompleteField.swift
//  d2d-studio
//
//  Created by Emin Okic on 10/20/25.
//

import SwiftUI
import MapKit

@available(iOS 18.0, *)
struct AddressAutocompleteField: View {
    @Binding var addressText: String
    @FocusState.Binding var isFocused: Bool
    @ObservedObject var searchViewModel: SearchCompleterViewModel

    var placeholder: String = "Address"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 🧩 Standard white TextField – matches iOS form design
            TextField(placeholder, text: $addressText)
                .focused($isFocused)
                .onChange(of: addressText) { newValue in
                    searchViewModel.updateQuery(newValue)
                }
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.vertical, 8)

            // 🧠 Polished suggestions list under the field (not inside it)
            if isFocused && !searchViewModel.results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchViewModel.results.prefix(5), id: \.self) { result in
                        Button {
                            SearchBarController.resolveAndSelectAddress(from: result) { resolved in
                                addressText = resolved
                                isFocused = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.body)
                                    .foregroundStyle(.tint)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                            .background(Color(.systemBackground))
                        }
                        .buttonStyle(.plain)

                        if result != searchViewModel.results.prefix(5).last {
                            Divider().padding(.leading, 32)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                )
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeOut(duration: 0.25), value: searchViewModel.results.count)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isFocused)
    }
}
