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
    // The visible region on the map.
    @Binding var region: MKCoordinateRegion

    // Search text typed by the user.
    @State private var searchText: String = ""
    // All of the “markers” that appear on the map.
    @State private var markers: [IdentifiablePlace] = []
    // The next three most recent search‐queries.  (Addresses only.)
    @State private var recentSearches: [String] = []
    
    // Whether to show the share‐sheet for the exported CSV
    @State private var showShareSheet: Bool = false
    // URL for the CSV that we’ll pass into the share‐sheet
    @State private var csvURL: URL? = nil
    
    // Whether to show the file‐importer dialog
    @State private var isImporterPresented: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // ──────────────────────────────────────────────────────────────────
            // 1) THE MAP WITH PIN ANNOTATIONS
            // ──────────────────────────────────────────────────────────────────
            Map(coordinateRegion: $region, annotationItems: markers) { place in
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
            
            // ──────────────────────────────────────────────────────────────────
            // 2) SEARCH BAR + EXPORT / IMPORT BUTTONS
            // ──────────────────────────────────────────────────────────────────
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search for a place…", text: $searchText, onCommit: {
                        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        performSearch(query: searchText.trimmingCharacters(in: .whitespaces))
                    })
                    .foregroundColor(.primary)
                    .autocapitalization(.words)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 3, x: 0, y: 2)
                
                Spacer().frame(width: 8)
                
                // Export button (disabled if there are no markers yet)
                Button {
                    let csvText = buildCSV(from: markers)
                    if let fileURL = saveCSVFile(content: csvText) {
                        self.csvURL = fileURL
                        self.showShareSheet = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(markers.isEmpty ? .gray : .blue)
                }
                .disabled(markers.isEmpty)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8)
                                .stroke(markers.isEmpty ? Color.gray : Color.blue, lineWidth: 1))
                .shadow(radius: 2, x: 0, y: 1)
                .sheet(isPresented: $showShareSheet) {
                    if let fileURL = csvURL {
                        ShareSheet(activityItems: [fileURL])
                    }
                }
                
                Spacer().frame(width: 8)
                
                // Import button
                Button {
                    isImporterPresented = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .shadow(radius: 2, x: 0, y: 1)
                .fileImporter(
                    isPresented: $isImporterPresented,
                    allowedContentTypes: [.commaSeparatedText],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            importCSV(from: url)
                        }
                    case .failure(let error):
                        print("File import failed: \(error)")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // ──────────────────────────────────────────────────────────────────
            // 3) RECENT SEARCHES SCROLL
            // ──────────────────────────────────────────────────────────────────
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(recentSearches, id: \.self) { query in
                        Button(action: {
                            performSearch(query: query)
                        }) {
                            Text(query)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 180)
            .padding(.top, 8)
            
            Spacer()  // push everything up
        }
        .onTapGesture {
            // Dismiss the keyboard if you tap outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    
    // MARK: - SEARCH / MARKER LOGIC
    
    /// Normalizes a query string (lowercased, trimmed).
    private func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    /// Called whenever the user hits “Return” in the search bar, or taps a recent search.
    private func performSearch(query: String) {
        let key = normalized(query)
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(query) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                return
            }
            
            DispatchQueue.main.async {
                // 1) If marker already exists, bump its count and recenter the map
                if let existing = markers.first(where: { normalized($0.address) == key }) {
                    existing.count += 1
                    region.center = existing.location
                }
                else {
                    // 2) Otherwise: create a brand‐new place and append it
                    let newPlace = IdentifiablePlace(address: query,
                                                     location: location.coordinate,
                                                     count: 1)
                    markers.append(newPlace)
                    region.center = location.coordinate
                }
                
                // 3) Keep ‘recentSearches’ in sync (dedupe + cap at 3)
                updateRecentSearches(with: query)
            }
        }
    }
    
    /// Adds a query to the front of the `recentSearches` array, deduping and keeping max 3.
    private func updateRecentSearches(with query: String) {
        let key = normalized(query)
        recentSearches.removeAll(where: { normalized($0) == key })
        recentSearches.insert(query, at: 0)
        if recentSearches.count > 3 {
            recentSearches = Array(recentSearches.prefix(3))
        }
    }
    
    
    // MARK: - CSV EXPORT / IMPORT
    
    /// Build a CSV string from our array of `IdentifiablePlace`.
    private func buildCSV(from places: [IdentifiablePlace]) -> String {
        var csv = "Address,Latitude,Longitude,Count\n"
        for place in places {
            let line = "\"\(place.address)\",\(place.location.latitude),\(place.location.longitude),\(place.count)"
            csv.append("\(line)\n")
        }
        return csv
    }
    
    /// Save that CSV string as a temporary file, returning its URL.
    private func saveCSVFile(content: String, fileName: String = "Knocks.csv") -> URL? {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
        let url = tempDir.appendingPathComponent(fileName)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error writing CSV: \(error)")
            return nil
        }
    }
    
    /// Read a CSV from disk, parse each row’s address, and re‐run `performSearch` on it.
    private func importCSV(from url: URL) {
        do {
            let content = try String(contentsOf: url)
            let lines = content
                .components(separatedBy: .newlines)
                .dropFirst()   // skip header
            for line in lines {
                let columns = line.components(separatedBy: ",")
                if let address = columns.first, !address.isEmpty {
                    performSearch(query: address.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        } catch {
            print("Failed to read CSV: \(error)")
        }
    }
}
