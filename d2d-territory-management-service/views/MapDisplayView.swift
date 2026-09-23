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
    var onMarkerLongPressed: (IdentifiablePlace) -> Void
    var onMapTapped: (CLLocationCoordinate2D) -> Void
    var onRegionChange: ((MKCoordinateRegion, Bool) -> Void)?

    static var cachedMapView: MKMapView?

    func makeCoordinator() -> MapDisplayCoordinator {
        MapDisplayCoordinator(
            userLocationManager: userLocationManager,
            selectedPlaceID: selectedPlaceID,
            onMarkerTapped: onMarkerTapped,
            onMarkerLongPressed: onMarkerLongPressed,
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
        tapGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(tapGesture)
        
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.20
        longPress.delegate = context.coordinator
        tapGesture.require(toFail: longPress)
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
        context.coordinator.onMarkerTapped = onMarkerTapped
        context.coordinator.onMarkerLongPressed = onMarkerLongPressed
        context.coordinator.onMapTapped = onMapTapped
        context.coordinator.onRegionChange = onRegionChange

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
        let markersByID = Dictionary(uniqueKeysWithValues: markers.map { ($0.id, $0) })
        let retainedMarkerAppearanceChanged = existing.reduce(false) { appearanceChanged, annotation in
            guard let updatedPlace = markersByID[annotation.place.id] else {
                return appearanceChanged
            }

            return annotation.update(with: updatedPlace) || appearanceChanged
        }

        if retainedMarkerAppearanceChanged {
            context.coordinator.refreshAllAnnotations(on: mapView)
        }
        
        if existingIds != newIds {
            let removedAnnotations = existing.filter { !newIds.contains($0.place.id) }
            let addedPlaces = markers.filter { !existingIds.contains($0.id) }

            for annotation in removedAnnotations {
                guard let view = mapView.view(for: annotation) else {
                    mapView.removeAnnotation(annotation)
                    continue
                }

                UIView.animate(
                    withDuration: 0.28,
                    delay: 0,
                    options: [.curveEaseIn, .beginFromCurrentState]
                ) {
                    view.alpha = 0
                    view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                } completion: { _ in
                    mapView.removeAnnotation(annotation)
                }
            }

            addedPlaces.forEach { mapView.addAnnotation(IdentifiableAnnotation(place: $0)) }
        }
    }
}
