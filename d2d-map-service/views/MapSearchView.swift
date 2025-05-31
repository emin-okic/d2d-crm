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
    @StateObject private var controller = MapController(region: MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    
    @State private var searchText: String = ""
    
    let prospects: [Prospect]
    
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
                        controller.performSearch(query: trimmed)
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
                onSelect: controller.performSearch(query:)
            )
            
            Spacer()
        }
        .onAppear {
            controller.addProspects(prospects)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                    controller.performSearch(query: address.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        } catch {
            print("Failed to read CSV: \(error)")
        }
    }
}
