//
//  MapSearchView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UniformTypeIdentifiers   // for .commaSeparatedText

struct MapSearchView: View {
    @Binding var region: MKCoordinateRegion
    @Binding var prospects: [Prospect]
    @Binding var selectedList: String   // ← The shared filter

    @StateObject private var controller: MapController
    @State private var searchText: String = ""

    init(region: Binding<MKCoordinateRegion>,
         prospects: Binding<[Prospect]>,
         selectedList: Binding<String>) {
        _region = region
        _prospects = prospects
        _selectedList = selectedList
        _controller = StateObject(wrappedValue: MapController(region: region.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 0) {
            Map(coordinateRegion: $controller.region,
                annotationItems: controller.markers) { place in
                MapAnnotation(coordinate: place.location) {
                    Circle()
                        .fill(place.markerColor)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                        .animation(.easeInOut, value: place.count)
                }
            }
            .frame(maxHeight: .infinity)
            .edgesIgnoringSafeArea(.horizontal)

            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search for a place…", text: $searchText, onCommit: {
                        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        handleSearch(query: trimmed)
                    })
                    .foregroundColor(.primary)
                    .autocapitalization(.words)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 3, x: 0, y: 2)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Spacer()
        }
        .onAppear {
            // First appearance: show only markers for `selectedList`
            let filtered = prospects.filter { $0.list == selectedList }
            controller.setMarkers(for: filtered)
        }
        .onChange(of: prospects) { newProspects in
            // If the array itself changes (new additions or edits), reload markers
            let filtered = newProspects.filter { $0.list == selectedList }
            controller.setMarkers(for: filtered)
        }
        .onChange(of: selectedList) { newList in
            // When you switch tabs (or pick “Customers”), reload markers for that list
            let filtered = prospects.filter { $0.list == newList }
            controller.setMarkers(for: filtered)
        }
        .onTapGesture {
            // Dismiss keyboard if you tap outside
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }

    private func handleSearch(query: String) {
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if let existingIndex = prospects.firstIndex(where: {
            $0.address
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .lowercased() == normalizedQuery
        }) {
            prospects[existingIndex].count += 1
        } else {
            // Always add new searches into the “Prospects” list by default
            let newProspect = Prospect(
                id: UUID(),
                fullName: "New Prospect",
                address: query,
                count: 1,
                list: "Prospects"
            )
            prospects.append(newProspect)
        }
        controller.performSearch(query: query)
    }
}
