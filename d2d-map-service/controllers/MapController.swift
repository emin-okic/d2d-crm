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
                    self.region.center = self.markers[existingIndex].location
                } else {
                    // Create new marker and recenter
                    let newPlace = IdentifiablePlace(address: query,
                                                    location: location.coordinate,
                                                    count: 1)
                    self.markers.append(newPlace)
                    self.region.center = location.coordinate
                }
                
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
}
