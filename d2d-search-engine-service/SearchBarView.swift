//
//  SearchBarView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//
import SwiftUI
import MapKit
import CoreLocation
import SwiftData
import Combine
import Contacts

struct SearchBarView: View {
    @Binding var searchText: String
    @FocusState.Binding var isFocused: Bool
    @ObservedObject var viewModel: SearchCompleterViewModel
    var onSubmit: () -> Void
    var onSelectResult: (MKLocalSearchCompletion) -> Void
    
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Enter a knock here…", text: $searchText, onCommit: {
                    onSubmit()
                })
                .focused($isFocused)
                .foregroundColor(.primary)
                .autocapitalization(.words)
                .submitLabel(.done)

                if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Done") {
                        onSubmit()
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .transition(.opacity)
                }

                // ⬅️ Add cancel button here
                Button(action: {
                    onCancel()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
                .padding(.leading, 6)
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .shadow(radius: 3, x: 0, y: 2)
            .padding(.horizontal)

            SearchSuggestionsListView(
                isVisible: isFocused,
                results: viewModel.results,
                onSelect: onSelectResult
            )
            
        }
        .padding(.bottom, 56)
        .animation(.easeInOut(duration: 0.25), value: viewModel.results.count)
    }
}
