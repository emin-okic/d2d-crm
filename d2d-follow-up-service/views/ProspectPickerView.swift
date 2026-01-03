//
//  ProspectPickerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/3/26.
//

import SwiftUI
import SwiftData

struct ProspectPickerView: View {
    let prospects: [Prospect]
    @Binding var selectedProspect: Prospect?
    @Environment(\.dismiss) private var dismiss
    var title: String = "Pick Prospect"

    // Optional: search state
    @State private var searchText: String = ""

    var filteredProspects: [Prospect] {
        if searchText.isEmpty { return prospects }
        return prospects.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 3)
                    .frame(width: 40, height: 5)
                    .foregroundColor(Color(.systemGray4))
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                // Optional search bar
                TextField("Search Prospects", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                
                ScrollView {
                    LazyVStack(spacing: 12, pinnedViews: []) {
                        ForEach(filteredProspects) { prospect in
                            Button {
                                selectedProspect = prospect
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(prospect.fullName)
                                        .font(.headline)
                                    Text(prospect.address)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        // DETENTED SHEET: only 50% height
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
    }
}
