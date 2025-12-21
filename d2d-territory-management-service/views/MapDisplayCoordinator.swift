//
//  MapDisplayCoordinator.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/20/25.
//

import MapKit
import Combine
import UIKit

final class MapDisplayCoordinator: NSObject, MKMapViewDelegate {

    let userLocationManager: UserLocationManager

    private var headingCancellable: AnyCancellable?
    weak var mapView: MKMapView?

    var onMarkerTapped: (IdentifiablePlace) -> Void
    var onMapTapped: (CLLocationCoordinate2D) -> Void
    var onRegionChange: ((MKCoordinateRegion) -> Void)?

    init(
        userLocationManager: UserLocationManager,
        onMarkerTapped: @escaping (IdentifiablePlace) -> Void,
        onMapTapped: @escaping (CLLocationCoordinate2D) -> Void,
        onRegionChange: ((MKCoordinateRegion) -> Void)? = nil
    ) {
        self.userLocationManager = userLocationManager
        self.onMarkerTapped = onMarkerTapped
        self.onMapTapped = onMapTapped
        self.onRegionChange = onRegionChange
        super.init()

        // 🔴 Live heading updates
        headingCancellable = userLocationManager.$heading
            .receive(on: RunLoop.main)
            .sink { [weak self] heading in
                guard
                    let self,
                    let mapView = self.mapView,
                    let heading,
                    let userView = mapView.view(for: mapView.userLocation),
                    let cone = userView.viewWithTag(200) as? DirectionConeView
                else { return }

                cone.updateHeading(heading.trueHeading)
            }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let mapView = gesture.view as? MKMapView else { return }
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

        let tappedAnnotations = mapView.annotations(in: mapView.visibleMapRect).filter {
            let viewPoint = mapView.convert((($0 as! MKAnnotation).coordinate), toPointTo: mapView)
            return hypot(viewPoint.x - point.x, viewPoint.y - point.y) < 30
        }

        if tappedAnnotations.isEmpty {
            onMapTapped(coordinate)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        if annotation is MKUserLocation {
            return userLocationView(for: mapView)
        }

        guard let annotation = annotation as? IdentifiableAnnotation else { return nil }

        // 🔴 If unqualified, use special view
        if annotation.place.isUnqualified {
            return unqualifiedMarkerView(for: annotation)
        }

        // Otherwise, standard marker
        return standardMarkerView(for: annotation)
    }

    // MARK: - Helpers

    private func unqualifiedMarkerView(for annotation: IdentifiableAnnotation) -> MKAnnotationView {
        let id = "unqualifiedMarker"
        let size: CGFloat = 30

        let view = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
        view.frame = CGRect(x: 0, y: 0, width: size, height: size)
        view.layer.cornerRadius = size / 2
        view.backgroundColor = .systemRed
        view.image = nil
        view.subviews.forEach { $0.removeFromSuperview() }

        // Add white X
        let xLabel = UILabel(frame: CGRect(x: 0, y: 0, width: size, height: size))
        xLabel.text = "✕"
        xLabel.textColor = .white
        xLabel.textAlignment = .center
        xLabel.font = .boldSystemFont(ofSize: size * 0.6)
        view.addSubview(xLabel)

        // Optional: subtle white border for map contrast
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor

        view.canShowCallout = false
        return view
    }

    private func standardMarkerView(for annotation: IdentifiableAnnotation) -> MKAnnotationView {
        let id = "customMarker"
        let view = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
        view.canShowCallout = false
        view.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        view.layer.cornerRadius = 14

        if annotation.place.list == "Customers" {
            view.image = UIImage(systemName: "star.circle.fill")?
                .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)

            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 1.5
            pulse.toValue = 1.0
            pulse.duration = 0.4
            pulse.timingFunction = CAMediaTimingFunction(name: .easeOut)
            view.layer.add(pulse, forKey: "pulse")
        } else {
            view.image = nil
            view.backgroundColor = UIColor(annotation.place.markerColor)
        }

        return view
    }

    private func userLocationView(for mapView: MKMapView) -> MKAnnotationView? {
        let id = "userLocation"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
            ?? MKAnnotationView(annotation: nil, reuseIdentifier: id)

        view.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        view.backgroundColor = .clear

        if view.viewWithTag(100) == nil {
            let dot = UIView(frame: CGRect(x: 12, y: 12, width: 16, height: 16))
            dot.backgroundColor = .systemBlue
            dot.layer.cornerRadius = 8
            dot.layer.borderWidth = 3
            dot.layer.borderColor = UIColor.white.cgColor
            dot.tag = 100

            let cone = DirectionConeView(frame: view.bounds)
            cone.tag = 200

            view.addSubview(cone)
            view.addSubview(dot)
        }

        if let cone = view.viewWithTag(200) as? DirectionConeView,
           let heading = userLocationManager.heading {
            cone.updateHeading(heading.trueHeading)
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
