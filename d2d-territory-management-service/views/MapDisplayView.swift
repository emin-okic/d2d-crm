//
//  MapDisplayView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//

import SwiftUI
import MapKit
import Combine

struct MapDisplayView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    
    var markers: [IdentifiablePlace]
    
    var userLocationManager: UserLocationManager
    
    var onMarkerTapped: (IdentifiablePlace) -> Void
    var onMapTapped: (CLLocationCoordinate2D) -> Void
    var onRegionChange: ((MKCoordinateRegion) -> Void)?      // NEW: notify region changes

    static var cachedMapView: MKMapView?

    func makeCoordinator() -> MapDisplayCoordinator {
        MapDisplayCoordinator(
            userLocationManager: userLocationManager,
            onMarkerTapped: onMarkerTapped,
            onMapTapped: onMapTapped,
            onRegionChange: onRegionChange
        )
    }

    func makeUIView(context: Context) -> MKMapView {
        
        let mapView = MKMapView()
        
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        
        mapView.setRegion(region, animated: false)
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.isRotateEnabled = true
        
        MapDisplayView.cachedMapView = mapView

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Sync region
        if abs(mapView.region.center.latitude - region.center.latitude) > 0.0001 ||
           abs(mapView.region.center.longitude - region.center.longitude) > 0.0001 ||
           abs(mapView.region.span.latitudeDelta - region.span.latitudeDelta) > 0.0001 ||
           abs(mapView.region.span.longitudeDelta - region.span.longitudeDelta) > 0.0001 {
            mapView.setRegion(region, animated: false)
        }
        // Sync annotations
        let existing = mapView.annotations.compactMap { $0 as? IdentifiableAnnotation }
        let existingIds = Set(existing.map { $0.place.id })
        let newIds = Set(markers.map { $0.id })
        if existingIds != newIds {
            mapView.removeAnnotations(mapView.annotations)
            for place in markers {
                let annotation = IdentifiableAnnotation(place: place)
                mapView.addAnnotation(annotation)
            }
        }
    }
}
