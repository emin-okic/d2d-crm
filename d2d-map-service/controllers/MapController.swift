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
    @Published var region: MKCoordinateRegion
    
    init(region: MKCoordinateRegion) {
        self.region = region
    }
    
    // Clears all existing markers immediately
    func clearMarkers() {
        markers.removeAll()
    }
    
    private func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
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
                if let existingIndex = self.markers.firstIndex(where: { self.normalized($0.address) == key }) {
                    self.markers[existingIndex].count += 1
                } else {
                    let newPlace = IdentifiablePlace(
                        address: query,
                        location: location.coordinate,
                        count: 1
                    )
                    self.markers.append(newPlace)
                }
                self.updateRegionToFitAllMarkers()
            }
        }
    }
    
    // Adjusts map region to fit all markers
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

        let latDelta = (maxLat - minLat) * 1.5
        let lonDelta = (maxLon - minLon) * 1.5

        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat,
                                           longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.01),
                                   longitudeDelta: max(lonDelta, 0.01))
        )
    }
    
    /// Adds markers for each prospect in the passed array (does NOT clear existing markers!)
    func addProspects(_ prospects: [Prospect]) {
        for prospect in prospects {
            performSearch(query: prospect.address)
        }
    }
    
    // Called when you want to show only these prospects’ markers
    func setMarkers(for prospects: [Prospect]) {
        // 1) Remove anything currently on the map
        clearMarkers()
        
        // 2) For each prospect, geocode its address and then append a new marker
        for prospect in prospects {
            let address = prospect.address
            let geocoder = CLGeocoder()
            
            geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
                guard let self = self else { return }
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    return
                }
                
                DispatchQueue.main.async {
                    let newPlace = IdentifiablePlace(
                        address: address,
                        location: location.coordinate,
                        count: prospect.count
                    )
                    self.markers.append(newPlace)
                    self.updateRegionToFitAllMarkers()
                }
            }
        }
    }

}
