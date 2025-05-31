//
//  MapController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation
import MapKit
import CoreLocation

class MapController: ObservableObject {
    @Published var markers: [IdentifiablePlace] = []
    @Published var recentSearches: [String] = []
    @Published var region: MKCoordinateRegion
    
    init(region: MKCoordinateRegion) {
        self.region = region
    }
    
    // Normalize query helper
    private func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    /**
     This function performs a search and places a marker
     */
    func performSearch(query: String) {
        let key = normalized(query)
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(query) { [weak self] placemarks, error in
            guard let self = self else { return }
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                return
            }
            
            DispatchQueue.main.async {
                // If marker exists, bump count and recenter map
                if let existingIndex = self.markers.firstIndex(where: { self.normalized($0.address) == key }) {
                    self.markers[existingIndex].count += 1
                } else {
                    let newPlace = IdentifiablePlace(address: query,
                                                     location: location.coordinate,
                                                     count: 1)
                    self.markers.append(newPlace)
                }

                self.updateRegionToFitAllMarkers()
                
                self.updateRecentSearches(with: query)
            }
        }
    }
    
    /**
     This function gets all the recent searches in a search session
     */
    public func updateRecentSearches(with query: String) {
        let key = normalized(query)
        recentSearches.removeAll(where: { normalized($0) == key })
        recentSearches.insert(query, at: 0)
        if recentSearches.count > 3 {
            recentSearches = Array(recentSearches.prefix(3))
        }
    }
    
    private func updateRegionToFitAllMarkers() {
        guard !markers.isEmpty else { return }

        let latitudes = markers.map { $0.location.latitude }
        let longitudes = markers.map { $0.location.longitude }

        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let latDelta = (maxLat - minLat) * 1.5 // add padding
        let lonDelta = (maxLon - minLon) * 1.5

        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.01), longitudeDelta: max(lonDelta, 0.01))
        )
    }

}
