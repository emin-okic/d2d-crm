//
//  ContentView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/28/25.
//

// SwiftUI and MapKit seem to be easy enough to use

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    
    // This variable seems to define the location of the mapkit UI
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // This variable defines the search text and manages what happens if it changes
    @State private var searchText = ""
    @State private var markers: [IdentifiablePlace] = []
    @State private var recentSearches: [String] = []
    
    @State private var showShareSheet = false
    @State private var csvURL: URL?
    
    @State private var isImporterPresented = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Map(coordinateRegion: $region, annotationItems: markers) { place in
                    MapAnnotation(coordinate: place.location) {
                        Circle()
                            .fill(place.markerColor)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1))
                            .animation(.easeInOut, value: place.count)
                    }
                }

                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search for a place...", text: $searchText, onCommit: {
                            searchLocation(query: searchText)
                        })
                        .foregroundColor(.primary)
                        
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .shadow(radius: 5)

                    Spacer()

                    Button(action: {
                        let csvText = exportCSV(from: markers)
                        if let fileURL = saveCSVFile(content: csvText) {
                            self.csvURL = fileURL
                            self.showShareSheet = true
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(markers.isEmpty ? .gray : .blue)
                            .imageScale(.large)

                    }
                    .padding(12)
                    .cornerRadius(12)
                    .disabled(markers.isEmpty)
                    .shadow(radius: 5)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    Button {
                        isImporterPresented = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .imageScale(.large)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                            .cornerRadius(12)
                    )
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
                .padding(12)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 50)
                .sheet(isPresented: $showShareSheet) {
                    if let fileURL = csvURL {
                        ShareSheet(activityItems: [fileURL])
                    }
                }
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(recentSearches, id: \.self) { query in
                            Button(action: { searchLocation(query: query) }) {
                                Text(query)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200)
                .padding(12)


            }
        }
    }
    
    
    func importCSV(from url: URL) {
        do {
            let content = try String(contentsOf: url)
            let lines = content.components(separatedBy: .newlines).dropFirst() // skip header
            
            for line in lines {
                let columns = line.components(separatedBy: ",")
                if let address = columns.first, !address.isEmpty {
                    searchLocation(query: address)
                }
            }
        } catch {
            print("Failed to read CSV: \(error)")
        }
    }


    func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
             .lowercased()
    }

    //
    // This function takes in a address as input and uses the GL Geocoder class
    // to create a coordinate for the map kit library to use.
    //
    func searchLocation(query: String) {
        let key = normalized(query)
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(query) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else { return }

            DispatchQueue.main.async {
                if let place = markers.first(where: { normalized($0.address) == key }) {
                    place.count += 1
                    region.center = place.location
                } else {
                    let newPlace = IdentifiablePlace(
                        address: query,
                        location: location.coordinate,
                        count: 1
                    )
                    markers.append(newPlace)
                    region.center = newPlace.location
                }
                updateRecentSearches(with: query)
            }
        }
    }

    //
    // The Update Recent Search Function
    //
    func updateRecentSearches(with query: String) {
        let key = normalized(query)
        recentSearches.removeAll(where: { normalized($0) == key })
        recentSearches.insert(query, at: 0)
        if recentSearches.count > 3 {
            recentSearches = Array(recentSearches.prefix(3))
        }
    }
    
    func exportCSV(from places: [IdentifiablePlace]) -> String {
        var csv = "Address,Latitude,Longitude,Count\n"
        for place in places {
            let line = "\"\(place.address)\",\(place.location.latitude),\(place.location.longitude),\(place.count)"
            csv.append(line + "\n")
        }
        return csv
    }

    func saveCSVFile(content: String, fileName: String = "Knocks.csv") -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing CSV file: \(error)")
            return nil
        }
    }
    
}



#Preview {
    ContentView()
}
