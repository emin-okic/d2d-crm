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

    func makeCoordinator() -> Coordinator {
        Coordinator(onMarkerTapped: onMarkerTapped, onMapTapped: onMapTapped)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: false)
        mapView.removeAnnotations(mapView.annotations)

        for place in markers {
            let annotation = IdentifiableAnnotation(place: place)
            mapView.addAnnotation(annotation)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var onMarkerTapped: (IdentifiablePlace) -> Void
        var onMapTapped: (CLLocationCoordinate2D) -> Void

        init(onMarkerTapped: @escaping (IdentifiablePlace) -> Void,
             onMapTapped: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onMarkerTapped = onMarkerTapped
            self.onMapTapped = onMapTapped
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }

            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            // Ensure tap isn't on a marker
            let tappedAnnotations = mapView.annotations(in: mapView.visibleMapRect).filter {
                let viewPoint = mapView.convert(($0 as! MKAnnotation).coordinate, toPointTo: mapView)
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
            view?.backgroundColor = UIColor(annotation.place.markerColor)

            // Custom icon if customer
            if annotation.place.list == "Customers" {
                view?.image = UIImage(systemName: "star.circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
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
    }
}

private class IdentifiableAnnotation: NSObject, MKAnnotation {
    let place: IdentifiablePlace

    var coordinate: CLLocationCoordinate2D {
        place.location
    }

    var title: String? {
        place.address
    }

    init(place: IdentifiablePlace) {
        self.place = place
    }
}
