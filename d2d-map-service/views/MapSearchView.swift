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
            controller.addProspects(prospects)
        }
        .onChange(of: prospects) { newProspects in
            for prospect in newProspects {
                if let index = controller.markers.firstIndex(where: {
                    $0.address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ==
                    prospect.address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                }) {
                    controller.markers[index].count = prospect.count
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }

    private func handleSearch(query: String) {
        // Normalize for comparison
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // 1) Check if there’s already a Prospect with the same normalized address
        if let existingIndex = prospects.firstIndex(where: {
            $0.address
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .lowercased() == normalizedQuery
        }) {
            // a) Increment that Prospect’s count
            prospects[existingIndex].count += 1

            // b) Tell the controller to use this updated Prospect for “recent searches”
            let updatedProspect = prospects[existingIndex]
            controller.updateRecentSearches(with: updatedProspect)

        } else {
            // 2) Otherwise—new prospect—for the first time
            let newProspect = Prospect(
                id: UUID(),
                fullName: "New Prospect",
                address: query,     // We’ll normalize later inside performSearch
                count: 1
            )
            prospects.append(newProspect)
            controller.updateRecentSearches(with: newProspect)
        }

        // 3) Finally, run the geocoding/marker logic
        controller.performSearch(query: query)
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
