//
//  MapDisplayView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//

import SwiftUI
import MapKit

struct MapDisplayView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var markers: [IdentifiablePlace]
    var onMarkerTapped: (IdentifiablePlace) -> Void
    var onMapTapped: (CLLocationCoordinate2D) -> Void
    var onRegionChange: ((MKCoordinateRegion) -> Void)?      // NEW: notify region changes

    static var cachedMapView: MKMapView?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onMarkerTapped: onMarkerTapped,
            onMapTapped: onMapTapped,
            onRegionChange: onRegionChange
        )
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsUserLocation = false
        MapDisplayView.cachedMapView = mapView

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        mapView.addGestureRecognizer(tapGesture)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Keep mapView region in sync with SwiftUI state
        if abs(mapView.region.center.latitude - region.center.latitude) > 0.0001 ||
           abs(mapView.region.center.longitude - region.center.longitude) > 0.0001 ||
           abs(mapView.region.span.latitudeDelta - region.span.latitudeDelta) > 0.0001 ||
           abs(mapView.region.span.longitudeDelta - region.span.longitudeDelta) > 0.0001 {
            mapView.setRegion(region, animated: false)
        }
        
        // Update annotations if marker list changed
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

    class Coordinator: NSObject, MKMapViewDelegate {
        var onMarkerTapped: (IdentifiablePlace) -> Void
        var onMapTapped: (CLLocationCoordinate2D) -> Void
        var onRegionChange: ((MKCoordinateRegion) -> Void)?

        init(
            onMarkerTapped: @escaping (IdentifiablePlace) -> Void,
            onMapTapped: @escaping (CLLocationCoordinate2D) -> Void,
            onRegionChange: ((MKCoordinateRegion) -> Void)? = nil
        ) {
            self.onMarkerTapped = onMarkerTapped
            self.onMapTapped = onMapTapped
            self.onRegionChange = onRegionChange
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            // If user tapped away from any annotation, treat as map tap
            let tappedAnnotations = mapView.annotations(in: mapView.visibleMapRect).filter {
                let viewPoint = mapView.convert((($0 as! MKAnnotation).coordinate), toPointTo: mapView)
                return hypot(viewPoint.x - point.x, viewPoint.y - point.y) < 30
            }
            if tappedAnnotations.isEmpty {
                onMapTapped(coordinate)
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? IdentifiableAnnotation else { return nil }
            let identifier = "customMarker"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = false
            } else {
                view?.annotation = annotation
            }
            view?.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
            view?.layer.cornerRadius = 14
            if annotation.place.list == "Customers" {
                view?.image = UIImage(systemName: "star.circle.fill")?
                    .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            } else {
                view?.image = nil
                view?.backgroundColor = UIColor(annotation.place.markerColor)
            }
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? IdentifiableAnnotation {
                onMarkerTapped(annotation.place)
            }
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            onRegionChange?(mapView.region)
        }
    }
}

private class IdentifiableAnnotation: NSObject, MKAnnotation {
    let place: IdentifiablePlace
    var coordinate: CLLocationCoordinate2D { place.location }
    var title: String? { place.address }
    init(place: IdentifiablePlace) { self.place = place }
}
