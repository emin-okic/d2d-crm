//
//  AddressInputField.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import SwiftUI


struct AddressInputField: View {
    var title: String
    @Binding var text: String
    @FocusState.Binding var focusedField: Field?
    var field: Field
    @ObservedObject var searchVM: SearchCompleterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                
                VStack(spacing: 0) {
                    TextField("Enter address", text: $text)
                        .focused($focusedField, equals: field)
                        .padding(14)
                        .onChange(of: text) { _, newValue in
                            searchVM.updateQuery(newValue)
                        }
                    
                    if focusedField == field,
                       let suggestion = searchVM.results.first,
                       text.isEmpty == false {
                        Button {
                            TripManagerHapticsController.shared.lightTap()
                            TripManagerSoundController.shared.playSound1()
                            
                            SearchBarController.resolveAndSelectAddress(from: suggestion) { resolved in
                                text = resolved
                                searchVM.results = []
                                focusedField = nil
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Use suggested address")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text(suggestion.title)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, -8)
                    }
                }
            }
        }
    }
}
