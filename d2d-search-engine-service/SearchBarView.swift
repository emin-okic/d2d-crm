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

            if isFocused && !viewModel.results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.results.prefix(3), id: \.self) { result in
                        Button {
                            onSelectResult(result)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title)
                                    .font(.body)
                                    .bold()
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Text(result.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 4)
                .shadow(radius: 4)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 180)
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .padding(.bottom, 56)
        .animation(.easeInOut(duration: 0.25), value: viewModel.results.count)
    }
}
