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
    
    private var activeRadiusOverlay: MKCircle?
    private let bulkAddRadius: CLLocationDistance = 35
    
    private var hasZoomedForActiveRadius = false

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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.7)
            renderer.lineWidth = 2
            renderer.fillColor = .clear
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    private func notifyBulkAdd(
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance
    ) {
        guard let mapView else { return }

        let centerLocation = CLLocation(
            latitude: center.latitude,
            longitude: center.longitude
        )

        // 1️⃣ Existing markers (if any)
        var properties: [PendingAddProperty] =
            mapView.annotations
                .compactMap { $0 as? IdentifiableAnnotation }
                .map { ann in
                    let loc = CLLocation(
                        latitude: ann.coordinate.latitude,
                        longitude: ann.coordinate.longitude
                    )
                    return (ann, loc)
                }
                .filter { $0.1.distance(from: centerLocation) <= radius }
                .map {
                    PendingAddProperty(
                        address: $0.0.place.address,
                        coordinate: $0.0.place.location
                    )
                }

        // 2️⃣ If NONE found → generate new properties
        if properties.isEmpty {
            properties = generateGrid(center: center, count: 6)
        }

        NotificationCenter.default.post(
            name: .didRequestBulkAdd,
            object: PendingBulkAdd(
                center: center,
                radius: radius,
                properties: properties
            )
        )
    }
    
    private func generateGrid(
        center: CLLocationCoordinate2D,
        count: Int
    ) -> [PendingAddProperty] {

        let spacingMeters: CLLocationDistance = 18
        let metersToDegrees = 1.0 / 111_000.0
        let delta = spacingMeters * metersToDegrees

        var results: [PendingAddProperty] = []

        for i in 0..<count {
            let offset = Double(i - count / 2)
            let coord = CLLocationCoordinate2D(
                latitude: center.latitude + offset * delta,
                longitude: center.longitude + offset * delta
            )

            results.append(
                PendingAddProperty(
                    address: "New Property \(i + 1)",
                    coordinate: coord
                )
            )
        }

        return results
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let mapView else { return }

        let point = gesture.location(in: mapView)
        let coord = mapView.convert(point, toCoordinateFrom: mapView)

        switch gesture.state {

        case .began:
            
            hasZoomedForActiveRadius = false

            // Remove old overlay if any
            if let overlay = activeRadiusOverlay {
                mapView.removeOverlay(overlay)
            }

            let circle = MKCircle(center: coord, radius: bulkAddRadius)
            activeRadiusOverlay = circle
            mapView.addOverlay(circle)
            
            // 🔍 Zoom in right away so user sees placement context
            zoomToBulkAddArea(center: coord, radius: bulkAddRadius)
            hasZoomedForActiveRadius = true

        case .changed:
            
            if let overlay = activeRadiusOverlay {
                mapView.removeOverlay(overlay)
            }

            let circle = MKCircle(center: coord, radius: bulkAddRadius)
            activeRadiusOverlay = circle
            mapView.addOverlay(circle)

        case .ended:
            
            guard let overlay = activeRadiusOverlay else { return }

            let center = overlay.coordinate
            let radius = overlay.radius

            // Brief pause so the user visually confirms placement
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self, let mapView = self.mapView else { return }

                // Fade out the ring
                self.fadeOutRadiusOverlay(overlay)

                // Remove overlay after fade
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    mapView.removeOverlay(overlay)
                    self.activeRadiusOverlay = nil
                }

                // Trigger bulk add
                self.notifyBulkAdd(center: center, radius: radius)
            }

        default:
            break
        }
    }
    
    private func fadeOutRadiusOverlay(
        _ overlay: MKCircle,
        duration: TimeInterval = 0.25
    ) {
        guard
            let mapView,
            let renderer = mapView.renderer(for: overlay) as? MKCircleRenderer
        else { return }

        let start = Date()
        let initialAlpha: CGFloat = 1.0

        renderer.alpha = initialAlpha

        let displayLink = CADisplayLink(target: BlockTarget { [weak renderer] link in
            let elapsed = Date().timeIntervalSince(start)
            let progress = min(elapsed / duration, 1.0)

            renderer?.alpha = initialAlpha * (1.0 - progress)

            if progress >= 1.0 {
                renderer?.alpha = 0.0
                link.invalidate()
            }
        }, selector: #selector(BlockTarget.tick))

        displayLink.add(to: .main, forMode: .common)
    }
    
    private final class BlockTarget {
        let block: (CADisplayLink) -> Void

        init(_ block: @escaping (CADisplayLink) -> Void) {
            self.block = block
        }

        @objc func tick(_ link: CADisplayLink) {
            block(link)
        }
    }
    
    private func zoomToBulkAddArea(
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        animated: Bool = true
    ) {
        guard let mapView else { return }

        // Slightly larger than the radius so the ring fits comfortably
        let paddingMultiplier: CLLocationDistance = 2.4

        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: radius * paddingMultiplier,
            longitudinalMeters: radius * paddingMultiplier
        )

        mapView.setRegion(region, animated: animated)
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
        
        // 🏢 Multi-unit ALWAYS wins
        if annotation.place.isMultiUnit {
            return buildingMarkerView(for: annotation)
        }

        // 🔴 If unqualified, use special view
        if annotation.place.isUnqualified {
            return unqualifiedMarkerView(for: annotation)
        }

        // Otherwise, standard marker
        return standardMarkerView(for: annotation)
    }
    
    private func buildingMarkerView(for annotation: IdentifiableAnnotation) -> MKAnnotationView {
        let id = "buildingMarker"

        let view =
            mapView?.dequeueReusableAnnotationView(withIdentifier: id)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)

        view.annotation = annotation
        view.canShowCallout = false
        
        // 🔒 HARD RESET (reuse-safe)
        view.layer.cornerRadius = 0
        view.layer.borderWidth = 0
        view.layer.borderColor = nil
        view.layer.shadowOpacity = 0
        view.layer.removeAllAnimations()
        view.backgroundColor = .clear
        
        view.frame.size = CGSize(width: 36, height: 36)

        // 🏢 Base building icon
        let imageView = UIImageView(
            image: UIImage(systemName: "building.2.crop.circle.fill")?
                .withTintColor(.systemGray, renderingMode: .alwaysOriginal)
        )
        imageView.frame = view.bounds
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)

        // view.backgroundColor = .clear
        view.layer.shadowOpacity = 0.25
        view.layer.shadowRadius = 4
        
        // 🔢 Unit count badge
        let count = annotation.place.unitCount
        if count > 1 {
            let badgeSize: CGFloat = 16

            let badge = UILabel()
            badge.text = "\(count)"
            badge.textColor = .white
            badge.font = .boldSystemFont(ofSize: 10)
            badge.textAlignment = .center
            badge.backgroundColor = .systemBlue
            badge.layer.cornerRadius = badgeSize / 2
            badge.layer.masksToBounds = true

            badge.frame = CGRect(
                x: view.bounds.maxX - badgeSize + 2,
                y: -2,
                width: badgeSize,
                height: badgeSize
            )

            view.addSubview(badge)
        }

        return view
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
        let view = mapView?.dequeueReusableAnnotationView(withIdentifier: id)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)

        view.annotation = annotation
        view.canShowCallout = false

        configure(view, for: annotation)

        // 🔢 Show badge if multiple contacts at same address (normal marker)
        if annotation.place.showsMultiContact {

            let badgeSize: CGFloat = 16

            let badge = UILabel()
            
            badge.text = "\(annotation.place.contactCount)"
            
            badge.textColor = .white
            badge.font = .boldSystemFont(ofSize: 10)
            badge.textAlignment = .center
            badge.backgroundColor = .systemBlue
            badge.layer.cornerRadius = badgeSize / 2
            badge.layer.masksToBounds = true

            badge.frame = CGRect(
                x: view.bounds.maxX - badgeSize + 2,
                y: -2,
                width: badgeSize,
                height: badgeSize
            )

            view.addSubview(badge)
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
        guard let annotation = view.annotation as? IdentifiableAnnotation else { return }

        selectedPlaceID = annotation.place.id
        onMarkerTapped(annotation.place)
        
        // ✅ Play the same feedback as adding a new property
        MapScreenHapticsController.shared.propertyAdded()
        MapScreenSoundController.shared.playPropertyAdded()

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
        
        // 🏢 Multi-unit markers NEVER get standard configuration
        if annotation.place.isMultiUnit {
            return
        }
        
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

extension Notification.Name {
    static let didRequestBulkAdd = Notification.Name("didRequestBulkAdd")
}
