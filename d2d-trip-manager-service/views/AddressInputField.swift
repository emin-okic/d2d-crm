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
                        .onChange(of: text) { searchVM.updateQuery($0) }
                    
                    if focusedField == field && !searchVM.results.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(searchVM.results.prefix(5), id: \.self) { result in
                                Button {
                                    SearchBarController.resolveAndSelectAddress(from: result) { resolved in
                                        text = resolved
                                        searchVM.results = []
                                        focusedField = nil
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title).bold()
                                        Text(result.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if result != searchVM.results.prefix(5).last {
                                    Divider().padding(.leading, 12)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        .padding(.top, -8)
                    }
                }
            }
        }
    }
}
