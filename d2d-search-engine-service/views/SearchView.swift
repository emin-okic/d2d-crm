//
//  SearchView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/30/25.
//
import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedProspect: Prospect?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // 🔍 Native-style search field
                TextField("Search prospects", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                ProspectSearchResultsView(
                    searchText: searchText,
                    selectedProspect: $selectedProspect
                )
            }
            .navigationTitle("Search")
            .navigationDestination(item: $selectedProspect) { prospect in
                ProspectDetailsView(prospect: prospect)
            }
        }
    }
}
