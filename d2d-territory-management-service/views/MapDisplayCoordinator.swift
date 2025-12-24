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
    
    var selectedPlaceID: UUID?

    init(
        userLocationManager: UserLocationManager,
        selectedPlaceID: UUID?,
        onMarkerTapped: @escaping (IdentifiablePlace) -> Void,
        onMapTapped: @escaping (CLLocationCoordinate2D) -> Void,
        onRegionChange: ((MKCoordinateRegion) -> Void)? = nil
    ) {
        self.userLocationManager = userLocationManager
        self.selectedPlaceID = selectedPlaceID
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
            
            selectedPlaceID = nil
            mapView.deselectAnnotation(mapView.selectedAnnotations.first, animated: false)
            
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

        let view =
            mapView?.dequeueReusableAnnotationView(withIdentifier: id)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)

        view.annotation = annotation
        view.frame = CGRect(x: 0, y: 0, width: size, height: size)
        view.layer.cornerRadius = size / 2
        view.backgroundColor = .systemRed
        view.image = nil
        view.canShowCallout = false

        // 🔴 Remove old subviews safely (reuse-proof)
        view.subviews.forEach { $0.removeFromSuperview() }

        // ❌ Centered X using Auto Layout (bulletproof)
        let xLabel = UILabel()
        xLabel.translatesAutoresizingMaskIntoConstraints = false
        xLabel.text = "✕"
        xLabel.textColor = .white
        xLabel.textAlignment = .center
        xLabel.font = .boldSystemFont(ofSize: size * 0.65)

        view.addSubview(xLabel)

        NSLayoutConstraint.activate([
            xLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            xLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Optional contrast ring
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor

        return view
    }

    private func standardMarkerView(for annotation: IdentifiableAnnotation) -> MKAnnotationView {

        let id = "customMarker"

        let view =
            mapView?.dequeueReusableAnnotationView(withIdentifier: id)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)

        view.annotation = annotation
        view.canShowCallout = false

        configure(view, for: annotation)

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
        guard let annotation = view.annotation as? IdentifiableAnnotation else { return }

        selectedPlaceID = annotation.place.id
        onMarkerTapped(annotation.place)

        refreshAllAnnotations(on: mapView)
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        refreshAllAnnotations(on: mapView)
    }
    
    private func refreshAllAnnotations(on mapView: MKMapView) {
        for annotation in mapView.annotations {
            guard
                let ann = annotation as? IdentifiableAnnotation,
                let view = mapView.view(for: ann)
            else { continue }

            configure(view, for: ann)
        }
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        onRegionChange?(mapView.region)
    }
    
    private func configure(
        _ view: MKAnnotationView,
        for annotation: IdentifiableAnnotation
    ) {
        let isSelected = annotation.place.id == selectedPlaceID

        let baseSize: CGFloat = annotation.place.list == "Customers" ? 46 : 28
        let selectedSize: CGFloat = annotation.place.list == "Customers" ? 58 : 40

        let size: CGFloat = isSelected ? selectedSize : baseSize
        
        view.frame.size = CGSize(width: size, height: size)
        view.layer.cornerRadius = size / 2

        // Reset state (CRITICAL)
        view.alpha = 1.0
        view.layer.borderWidth = 0
        view.layer.shadowOpacity = 0
        view.layer.removeAllAnimations()

        if annotation.place.list == "Customers" {
            view.image = UIImage(systemName: "star.circle.fill")?
                .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            view.backgroundColor = .clear
        } else {
            view.image = nil
            view.backgroundColor = UIColor(annotation.place.markerColor)
        }

        if isSelected {
            view.layer.borderWidth = 3
            view.layer.borderColor = UIColor.white.cgColor
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = 0.4
            view.layer.shadowRadius = 6

            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 0.85
            pulse.toValue = 1.0
            pulse.duration = 0.2
            view.layer.add(pulse, forKey: "selectPulse")
        } else {
            view.alpha = selectedPlaceID == nil ? 1.0 : 0.45
        }
    }
    
}
