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
    var onRegionChange: ((MKCoordinateRegion, Bool) -> Void)?
    
    var selectedPlaceID: UUID?
    
    private var activeRadiusOverlay: MKCircle?
    private var currentZoomSizeBucket: Int?
    private var isUserDrivenRegionChange = false
    private let bulkAddRadius: CLLocationDistance = 35
    
    private var hasZoomedForActiveRadius = false
    private var pendingSparkleCoordinates: [CLLocationCoordinate2D] = []

    init(
        userLocationManager: UserLocationManager,
        selectedPlaceID: UUID?,
        onMarkerTapped: @escaping (IdentifiablePlace) -> Void,
        onMapTapped: @escaping (CLLocationCoordinate2D) -> Void,
        onRegionChange: ((MKCoordinateRegion, Bool) -> Void)? = nil
    ) {
        self.userLocationManager = userLocationManager
        self.selectedPlaceID = selectedPlaceID
        self.onMarkerTapped = onMarkerTapped
        self.onMapTapped = onMapTapped
        self.onRegionChange = onRegionChange
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePropertyMarkerAdded(_:)),
            name: .didAddPropertyMarker,
            object: nil
        )

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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handlePropertyMarkerAdded(_ notification: Notification) {
        guard let location = notification.userInfo?["location"] as? CLLocation else { return }

        let coordinate = location.coordinate
        pendingSparkleCoordinates.append(coordinate)
        animateSparkleIfPossible(at: coordinate)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.pendingSparkleCoordinates.removeAll { pending in
                self?.coordinatesAreClose(pending, coordinate) == true
            }
        }
    }
    
    func updateSelectedPlaceID(_ id: UUID?) {
        selectedPlaceID = id
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: route)
            renderer.strokeColor = UIColor.white.withAlphaComponent(0.86)
            renderer.lineWidth = 4
            renderer.lineCap = .round
            renderer.lineDashPattern = [2, 9]
            return renderer
        }

        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.strokeColor = UIColor.systemMint.withAlphaComponent(0.82)
            renderer.lineWidth = 3
            renderer.lineDashPattern = [8, 7]
            renderer.fillColor = UIColor.systemMint.withAlphaComponent(0.08)
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
            
            // 🏆 Strong reward feedback
            MapScreenHapticsController.shared.propertyAdded()
            MapScreenSoundController.shared.playPropertyAdded()
            
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
            
            // 🏆 Strong reward feedback
            MapScreenHapticsController.shared.propertyAdded()
            MapScreenSoundController.shared.playPropertyAdded()

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

        if annotation.place.list == "PendingProperty" {
            return pendingPropertyMarkerView(for: annotation)
        }
        
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
        configureBuildingMarker(view, for: annotation)

        return view
    }

    private func configureBuildingMarker(_ view: MKAnnotationView, for annotation: IdentifiableAnnotation) {
        view.subviews.forEach { $0.removeFromSuperview() }
        view.layer.sublayers?
            .filter { $0.name == "selectionRing" || $0.name == "pendingPropertyGuide" }
            .forEach { $0.removeFromSuperlayer() }
        view.layer.cornerRadius = 0
        view.layer.borderWidth = 0
        view.layer.borderColor = nil
        view.layer.removeAllAnimations()
        view.backgroundColor = .clear
        view.image = nil
        
        let isSelected = annotation.place.id == selectedPlaceID
        let size = markerSize(for: annotation.place, isSelected: isSelected, minimumSize: 50, selectedMinimumSize: 80)
        view.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        view.centerOffset = CGPoint(x: 0, y: -size * 0.18)

        let token = UIView(frame: view.bounds.insetBy(dx: isSelected ? 7 : 5, dy: isSelected ? 7 : 5))
        token.backgroundColor = UIColor.systemIndigo
        token.layer.cornerRadius = token.bounds.width / 2
        token.layer.borderWidth = isSelected ? 2.5 : 2
        token.layer.borderColor = UIColor.white.withAlphaComponent(0.92).cgColor
        token.layer.shadowColor = UIColor.black.cgColor
        token.layer.shadowOpacity = isSelected ? 0.48 : 0.38
        token.layer.shadowRadius = isSelected ? 11 : 8
        token.layer.shadowOffset = CGSize(width: 0, height: isSelected ? 7 : 5)

        let imageView = UIImageView(
            image: UIImage(systemName: "building.2.crop.circle.fill")?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
        )
        imageView.frame = token.bounds.insetBy(dx: token.bounds.width * 0.14, dy: token.bounds.height * 0.14)
        imageView.contentMode = .scaleAspectFit
        token.addSubview(imageView)
        view.addSubview(token)

        if isSelected {
            applySelectionRing(to: view, size: size)
        }

        view.layer.shadowOpacity = 0
        
        let count = annotation.place.unitCount
        if count > 1 {
            let badgeSize = max(18, size * 0.26)

            let badge = UILabel()
            badge.text = "\(count)"
            badge.textColor = .white
            badge.font = .boldSystemFont(ofSize: max(10, badgeSize * 0.54))
            badge.textAlignment = .center
            badge.backgroundColor = .systemBlue
            badge.layer.cornerRadius = badgeSize / 2
            badge.layer.masksToBounds = true

            badge.frame = CGRect(
                x: view.bounds.maxX - badgeSize + 1,
                y: -1,
                width: badgeSize,
                height: badgeSize
            )

            view.addSubview(badge)
        }
    }

    // MARK: - Helpers

    private func pendingPropertyMarkerView(for annotation: IdentifiableAnnotation) -> MKAnnotationView {
        let id = "pendingPropertyMarker"
        let view = mapView?.dequeueReusableAnnotationView(withIdentifier: id)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)

        view.annotation = annotation
        view.canShowCallout = false
        configurePendingPropertyMarker(view)

        return view
    }

    private func configurePendingPropertyMarker(_ view: MKAnnotationView) {
        view.subviews.forEach { $0.removeFromSuperview() }
        view.layer.sublayers?
            .filter { $0.name == "selectionRing" || $0.name == "pendingPropertyGuide" }
            .forEach { $0.removeFromSuperlayer() }
        view.layer.removeAllAnimations()
        view.backgroundColor = .clear
        view.image = nil
        view.layer.shadowOpacity = 0
        view.bounds = CGRect(x: 0, y: 0, width: 62, height: 92)
        view.centerOffset = CGPoint(x: 0, y: -46)

        let guideLayer = CAShapeLayer()
        guideLayer.name = "pendingPropertyGuide"
        guideLayer.strokeColor = UIColor.systemRed.withAlphaComponent(0.9).cgColor
        guideLayer.lineWidth = 2.5
        guideLayer.lineDashPattern = [3, 5]
        guideLayer.lineCap = .round
        let guidePath = UIBezierPath()
        guidePath.move(to: CGPoint(x: view.bounds.midX, y: 42))
        guidePath.addLine(to: CGPoint(x: view.bounds.midX, y: 84))
        guideLayer.path = guidePath.cgPath
        view.layer.addSublayer(guideLayer)

        let targetDot = UIView(frame: CGRect(x: view.bounds.midX - 5, y: 80, width: 10, height: 10))
        targetDot.backgroundColor = .systemRed
        targetDot.layer.cornerRadius = 5
        targetDot.layer.borderWidth = 2
        targetDot.layer.borderColor = UIColor.white.cgColor
        view.addSubview(targetDot)

        let pin = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        pin.tintColor = .systemRed
        pin.contentMode = .scaleAspectFit
        pin.frame = CGRect(x: 10, y: 0, width: 42, height: 42)
        pin.layer.shadowColor = UIColor.black.cgColor
        pin.layer.shadowOpacity = 0.3
        pin.layer.shadowRadius = 7
        pin.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.addSubview(pin)

        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.92
        pulse.toValue = 1.06
        pulse.duration = 0.7
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pin.layer.add(pulse, forKey: "pendingPinPulse")
    }

    private func unqualifiedMarkerView(for annotation: IdentifiableAnnotation) -> MKAnnotationView {
        let id = "unqualifiedMarker"
        let view =
            mapView?.dequeueReusableAnnotationView(withIdentifier: id)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)

        view.annotation = annotation
        view.canShowCallout = false
        let isSelected = annotation.place.id == selectedPlaceID
        configurePropertyToken(
            view,
            for: annotation.place,
            size: markerSize(for: annotation.place, isSelected: isSelected, minimumSize: 42, selectedMinimumSize: 66),
            isSelected: isSelected,
            symbolName: "xmark"
        )

        return view
    }

    private func standardMarkerView(for annotation: IdentifiableAnnotation) -> MKAnnotationView {
        let id = "customMarker"
        let view = mapView?.dequeueReusableAnnotationView(withIdentifier: id)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
        view.annotation = annotation
        view.canShowCallout = false
        view.subviews.forEach { $0.removeFromSuperview() } // reset reuse

        configure(view, for: annotation)

        // Only show multi-contact badge if not multi-unit
        if !annotation.place.isMultiUnit && annotation.place.showsMultiContact {
            addBadge(to: view, count: annotation.place.contactCount)
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

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            guard let annotation = view.annotation as? IdentifiableAnnotation else { continue }

            if pendingSparkleCoordinates.contains(where: { coordinatesAreClose($0, annotation.coordinate) }) {
                pendingSparkleCoordinates.removeAll { coordinatesAreClose($0, annotation.coordinate) }
                addMarkerSparkle(to: view)
            }
        }
    }

    private func animateSparkleIfPossible(at coordinate: CLLocationCoordinate2D) {
        guard let mapView else { return }

        for annotation in mapView.annotations {
            guard
                let placeAnnotation = annotation as? IdentifiableAnnotation,
                coordinatesAreClose(placeAnnotation.coordinate, coordinate),
                let view = mapView.view(for: placeAnnotation)
            else { continue }

            pendingSparkleCoordinates.removeAll { coordinatesAreClose($0, coordinate) }
            addMarkerSparkle(to: view)
            return
        }
    }

    private func coordinatesAreClose(_ first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> Bool {
        let firstLocation = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let secondLocation = CLLocation(latitude: second.latitude, longitude: second.longitude)
        return firstLocation.distance(from: secondLocation) < 4
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

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        isUserDrivenRegionChange = mapView.gestureRecognizers?.contains {
            $0.state == .began || $0.state == .changed
        } == true
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        isUserDrivenRegionChange = false
    }

    private func addMarkerSparkle(to view: MKAnnotationView) {
        let sparkleTag = 901
        view.viewWithTag(sparkleTag)?.removeFromSuperview()

        let sparkleSize = max(24, view.bounds.width * 0.42)
        let sparkle = UIImageView(
            image: UIImage(systemName: "sparkles")?
                .withRenderingMode(.alwaysTemplate)
        )
        sparkle.tag = sparkleTag
        sparkle.tintColor = .systemYellow
        sparkle.contentMode = .scaleAspectFit
        sparkle.frame = CGRect(
            x: view.bounds.maxX - sparkleSize * 0.72,
            y: -sparkleSize * 0.20,
            width: sparkleSize,
            height: sparkleSize
        )
        sparkle.layer.shadowColor = UIColor.white.cgColor
        sparkle.layer.shadowOpacity = 0.9
        sparkle.layer.shadowRadius = 6
        sparkle.layer.shadowOffset = .zero
        sparkle.alpha = 0
        sparkle.transform = CGAffineTransform(scaleX: 0.35, y: 0.35).rotated(by: -0.35)
        view.addSubview(sparkle)

        let pop = CAKeyframeAnimation(keyPath: "transform.scale")
        pop.values = [0.88, 1.16, 0.98, 1.0]
        pop.keyTimes = [0, 0.42, 0.78, 1]
        pop.duration = 0.42
        pop.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeOut)
        ]
        view.layer.add(pop, forKey: "propertyAddedPop")

        UIView.animateKeyframes(withDuration: 0.95, delay: 0, options: [.calculationModeCubic]) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.22) {
                sparkle.alpha = 1
                sparkle.transform = CGAffineTransform(scaleX: 1.25, y: 1.25).rotated(by: 0.18)
            }

            UIView.addKeyframe(withRelativeStartTime: 0.22, relativeDuration: 0.34) {
                sparkle.transform = CGAffineTransform(scaleX: 0.92, y: 0.92).rotated(by: 0.52)
            }

            UIView.addKeyframe(withRelativeStartTime: 0.58, relativeDuration: 0.42) {
                sparkle.alpha = 0
                sparkle.transform = CGAffineTransform(scaleX: 1.7, y: 1.7).rotated(by: 0.9)
            }
        } completion: { _ in
            DispatchQueue.main.async {
                sparkle.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Badge Helper
    private func addBadge(
        to view: MKAnnotationView,
        count: Int,
        color: UIColor = .systemBlue,
        size: CGFloat = 16
    ) {
        guard count > 1 else { return }

        let badge = UILabel()
        badge.text = "\(count)"
        badge.textColor = .white
        badge.font = .boldSystemFont(ofSize: 10)
        badge.textAlignment = .center
        badge.backgroundColor = color
        badge.layer.cornerRadius = size / 2
        badge.layer.masksToBounds = true
        badge.frame = CGRect(
            x: view.bounds.maxX - size + 2,
            y: -2,
            width: size,
            height: size
        )
        view.addSubview(badge)
    }
    
    func refreshAllAnnotations(on mapView: MKMapView) {
        for annotation in mapView.annotations {
            guard
                let ann = annotation as? IdentifiableAnnotation,
                let view = mapView.view(for: ann)
            else { continue }

            configure(view, for: ann)
        }
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let nextBucket = zoomSizeBucket(for: mapView)
        if currentZoomSizeBucket != nextBucket {
            currentZoomSizeBucket = nextBucket
            refreshAllAnnotations(on: mapView)
        }

        let region = mapView.region
        let isUserDriven = isUserDrivenRegionChange
        DispatchQueue.main.async { [onRegionChange] in
            onRegionChange?(region, isUserDriven)
        }
    }
    
    private func zoomScaleFactor() -> CGFloat {
        guard let mapView else { return 1.0 }
        let span = max(mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta)

        switch span {
        case ...0.002:
            return 1.42
        case ...0.006:
            return 1.28
        case ...0.015:
            return 1.14
        case ...0.04:
            return 1.0
        default:
            return 0.9
        }
    }

    private func zoomSizeBucket(for mapView: MKMapView) -> Int {
        let span = max(mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta)

        switch span {
        case ...0.002:
            return 4
        case ...0.006:
            return 3
        case ...0.015:
            return 2
        case ...0.04:
            return 1
        default:
            return 0
        }
    }

    private func markerSize(
        for place: IdentifiablePlace,
        isSelected: Bool,
        minimumSize: CGFloat? = nil,
        selectedMinimumSize: CGFloat? = nil
    ) -> CGFloat {
        let base = place.list == "Customers" ? 60.0 : 42.0
        let selectedBase = place.list == "Customers" ? 88.0 : 68.0
        let rawSize = (isSelected ? selectedBase : base) * zoomScaleFactor()

        if isSelected, let selectedMinimumSize {
            return max(rawSize, selectedMinimumSize)
        }

        if let minimumSize {
            return max(rawSize, minimumSize)
        }

        return rawSize
    }
    
    private func applySelectionRing(to view: MKAnnotationView, size: CGFloat) {
        view.layer.sublayers?
            .filter { $0.name == "selectionRing" }
            .forEach { $0.removeFromSuperlayer() }

        let outerBounds = view.bounds.insetBy(dx: 2, dy: 2)
        let ringLayer = CAShapeLayer()
        ringLayer.name = "selectionRing"
        ringLayer.frame = view.bounds
        ringLayer.path = UIBezierPath(ovalIn: outerBounds).cgPath
        ringLayer.fillColor = UIColor.systemMint.withAlphaComponent(0.15).cgColor
        ringLayer.strokeColor = UIColor.white.withAlphaComponent(0.95).cgColor
        ringLayer.lineWidth = 3
        view.layer.insertSublayer(ringLayer, at: 0)
    }
    
    private func configurePropertyToken(
        _ view: MKAnnotationView,
        for place: IdentifiablePlace,
        size: CGFloat,
        isSelected: Bool,
        symbolName: String? = nil
    ) {
        view.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        view.centerOffset = CGPoint(x: 0, y: -size * 0.18)
        view.backgroundColor = .clear
        view.image = nil
        view.layer.cornerRadius = 0
        view.layer.borderWidth = 0
        view.layer.shadowOpacity = 0
        view.layer.removeAllAnimations()
        view.subviews.forEach { $0.removeFromSuperview() }
        view.layer.sublayers?
            .filter { $0.name == "selectionRing" }
            .forEach { $0.removeFromSuperlayer() }

        let fillColor = UIColor(place.markerColor)
        let haloInset: CGFloat = isSelected ? 0 : 3
        let halo = UIView(frame: view.bounds.insetBy(dx: haloInset, dy: haloInset))
        halo.backgroundColor = fillColor.withAlphaComponent(isSelected ? 0.20 : 0.10)
        halo.layer.cornerRadius = halo.bounds.width / 2
        halo.layer.borderWidth = 1
        halo.layer.borderColor = UIColor.white.withAlphaComponent(isSelected ? 0.35 : 0.18).cgColor
        view.addSubview(halo)

        let tokenInset: CGFloat = isSelected ? 7 : 5
        let token = UIView(frame: view.bounds.insetBy(dx: tokenInset, dy: tokenInset))
        token.backgroundColor = fillColor
        token.layer.cornerRadius = token.bounds.width / 2
        token.layer.borderWidth = isSelected ? 2.5 : 2
        token.layer.borderColor = UIColor.white.withAlphaComponent(0.92).cgColor
        token.layer.shadowColor = UIColor.black.cgColor
        token.layer.shadowOpacity = isSelected ? 0.48 : 0.32
        token.layer.shadowRadius = isSelected ? 10 : 7
        token.layer.shadowOffset = CGSize(width: 0, height: isSelected ? 7 : 4)
        view.addSubview(token)

        let symbol = symbolName ?? (place.list == "Customers" ? "star.fill" : "house.fill")
        let config = UIImage.SymbolConfiguration(pointSize: token.bounds.width * 0.64, weight: .semibold)
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: config))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.frame = token.bounds.insetBy(dx: token.bounds.width * 0.14, dy: token.bounds.height * 0.14)
        token.addSubview(icon)

        if isSelected {
            applySelectionRing(to: view, size: size)

            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 0.88
            pulse.toValue = 1.0
            pulse.duration = 0.2
            view.layer.add(pulse, forKey: "selectPulse")
        }
    }
    
    private func configure(
        _ view: MKAnnotationView,
        for annotation: IdentifiableAnnotation
    ) {
        if annotation.place.list == "PendingProperty" {
            configurePendingPropertyMarker(view)
            return
        }

        if annotation.place.isMultiUnit {
            configureBuildingMarker(view, for: annotation)
            return
        }
        
        let isSelected = annotation.place.id == selectedPlaceID
        let size = markerSize(for: annotation.place, isSelected: isSelected)

        configurePropertyToken(
            view,
            for: annotation.place,
            size: size,
            isSelected: isSelected
        )

        view.alpha = selectedPlaceID == nil || isSelected ? 1.0 : 0.42
    }
    
}

extension Notification.Name {
    static let didRequestBulkAdd = Notification.Name("didRequestBulkAdd")
    static let didAddPropertyMarker = Notification.Name("didAddPropertyMarker")
}
