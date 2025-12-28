//
//  GlobalSearchView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//

import SwiftUI
import MapKit

struct GlobalSearchView: View {

    @Binding var searchText: String
    @Binding var selectedTab: Int

    @State private var isExpanded = true
    @FocusState private var isFocused: Bool
    @Namespace private var searchNamespace

    @StateObject private var mapCompleter = SearchCompleterViewModel()

    var body: some View {
        VStack {
            ExpandableSearchView(
                searchText: $searchText,
                isExpanded: $isExpanded,
                isFocused: $isFocused,
                viewModel: mapCompleter,
                animationNamespace: searchNamespace,
                onSubmit: {
                    routeBackToMap()
                },
                onSelectResult: { completion in
                    mapCompleter.select(completion)
                    routeBackToMap()
                }
            )
            Spacer()
        }
        .onAppear {
            isExpanded = true
            isFocused = true
        }
        .navigationTitle("Search")
    }

    private func routeBackToMap() {
        selectedTab = 0 // switch back to Map tab
    }
}
