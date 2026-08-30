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
    
    var selectedPlaceID: UUID?
    
    var userLocationManager: UserLocationManager
    
    var onMarkerTapped: (IdentifiablePlace) -> Void
    var onMapTapped: (CLLocationCoordinate2D) -> Void
    var onRegionChange: ((MKCoordinateRegion, Bool) -> Void)?

    static var cachedMapView: MKMapView?

    func makeCoordinator() -> MapDisplayCoordinator {
        MapDisplayCoordinator(
            userLocationManager: userLocationManager,
            selectedPlaceID: selectedPlaceID,
            onMarkerTapped: onMarkerTapped,
            onMapTapped: onMapTapped,
            onRegionChange: onRegionChange
        )
    }

    func makeUIView(context: Context) -> MKMapView {
        
        let mapView = MKMapView()
        
        mapView.delegate = context.coordinator
        context.coordinator.attach(mapView: mapView)
        configureMapAppearance(mapView)
        
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
        
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.35
        mapView.addGestureRecognizer(longPress)
        
        return mapView
    }

    private func configureMapAppearance(_ mapView: MKMapView) {
        if #available(iOS 16.0, *) {
            let configuration = MKStandardMapConfiguration(elevationStyle: .realistic)
            configuration.emphasisStyle = .muted
            configuration.pointOfInterestFilter = .excludingAll
            mapView.preferredConfiguration = configuration
        } else {
            mapView.mapType = .mutedStandard
            mapView.pointOfInterestFilter = .excludingAll
        }

        mapView.showsBuildings = true
        mapView.showsCompass = true
        mapView.showsScale = false
        mapView.isPitchEnabled = true

        let camera = MKMapCamera(
            lookingAtCenter: region.center,
            fromDistance: 900,
            pitch: 56,
            heading: 0
        )
        mapView.setCamera(camera, animated: false)
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        
        // 🔄 Sync selected marker
        if context.coordinator.selectedPlaceID != selectedPlaceID {
            
            context.coordinator.updateSelectedPlaceID(selectedPlaceID)
            context.coordinator.refreshAllAnnotations(on: mapView)
            
        }
        
        // Sync programmatic region changes through MapKit's camera interpolation.
        if abs(mapView.region.center.latitude - region.center.latitude) > 0.0001 ||
           abs(mapView.region.center.longitude - region.center.longitude) > 0.0001 ||
           abs(mapView.region.span.latitudeDelta - region.span.latitudeDelta) > 0.0001 ||
           abs(mapView.region.span.longitudeDelta - region.span.longitudeDelta) > 0.0001 {
            mapView.setRegion(region, animated: true)
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
