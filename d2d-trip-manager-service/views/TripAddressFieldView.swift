//
//  TripAddressFieldView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/4/25.
//


import SwiftUI
import MapKit

struct TripAddressFieldView: View {
    var iconName: String
    var placeholder: String
    var iconColor: Color

    @Binding var addressText: String
    
    var focusedField: FocusState<Field?>.Binding
    
    var fieldType: Field

    @ObservedObject var searchVM: SearchCompleterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                TextField(placeholder, text: $addressText)
                    .focused(focusedField, equals: fieldType)
                    .onChange(of: addressText) { searchVM.updateQuery($0) }
            }

            if focusedField.wrappedValue == fieldType && !searchVM.results.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(searchVM.results.prefix(3), id: \.self) { result in
                        Button {
                            SearchBarController.resolveAndSelectAddress(from: result) { resolved in
                                addressText = resolved
                                searchVM.results = []
                                focusedField.wrappedValue = nil
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(result.title).bold()
                                Text(result.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
