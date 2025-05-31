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

    @StateObject private var controller: MapController

    @State private var searchText: String = ""

    init(region: Binding<MKCoordinateRegion>, prospects: Binding<[Prospect]>) {
        // Initialize the MapController with the starting region
        // We need to unwrap the binding’s wrappedValue here
        _region = region
        _prospects = prospects
        _controller = StateObject(wrappedValue: MapController(region: region.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 0) {
            Map(coordinateRegion: $controller.region, annotationItems: controller.markers) { place in
                MapAnnotation(coordinate: place.location) {
                    Circle()
                        .fill(place.markerColor)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                        .animation(.easeInOut, value: place.count)
                }
            }
            .frame(height: 300)
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

                Spacer().frame(width: 8)

                ImportExportView(markers: controller.markers, onImport: { url in
                    importCSV(from: url)
                })
            }
            .padding(.horizontal)
            .padding(.top, 12)

            RecentSearchesView(
                recentSearches: controller.recentSearches,
                onSelect: { query in handleSearch(query: query) }
            )

            Spacer()
        }
        .onAppear {
            controller.addProspects(prospects)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }

    private func handleSearch(query: String) {
        controller.performSearch(query: query)

        // After the map controller adds/updates the marker, check if we need to insert a Prospect:
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let alreadyExists = prospects.contains {
            $0.address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized
        }

        if !alreadyExists {
            // Create a new Prospect. You can adjust fullName as needed;
            // here we’re just setting the name to “New Prospect” as a placeholder
            let newProspect = Prospect(
                id: UUID(),
                fullName: "New Prospect",
                address: query
            )
            prospects.append(newProspect)
        }
    }

    private func importCSV(from url: URL) {
        do {
            let content = try String(contentsOf: url)
            let lines = content
                .components(separatedBy: .newlines)
                .dropFirst()   // skip header
            for line in lines {
                let columns = line.components(separatedBy: ",")
                if let address = columns.first, !address.isEmpty {
                    handleSearch(query: address.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        } catch {
            print("Failed to read CSV: \(error)")
        }
    }
}
