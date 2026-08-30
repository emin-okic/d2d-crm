//
//  BulkAddRadiusOverlayController.swift
//  d2d-studio
//
//  Created by Codex on 8/30/26.
//

import CoreLocation
import MapKit
import UIKit

@MainActor
final class BulkAddRadiusOverlayController: NSObject {

    private weak var mapView: MKMapView?
    private var previewView: BulkAddRadiusPreviewView?
    private var currentCenter: CLLocationCoordinate2D?
    private var currentRadius: CLLocationDistance = 0
    private var fadeAnimator: UIViewPropertyAnimator?
    private var edgePanDisplayLink: CADisplayLink?
    private var latestTouchPoint: CGPoint?
    private let edgePanStartOverflowRatio: CGFloat = 0.42
    private let edgePanFullSpeedOverflowRatio: CGFloat = 0.95
    private let maximumEdgePanSpeed: CGFloat = 260

    var center: CLLocationCoordinate2D? {
        currentCenter
    }

    var radius: CLLocationDistance {
        currentRadius
    }

    init(mapView: MKMapView) {
        self.mapView = mapView
        super.init()
    }

    func begin(at coordinate: CLLocationCoordinate2D, touchPoint: CGPoint, radius: CLLocationDistance) {
        fadeAnimator?.stopAnimation(true)
        stopEdgePan()
        previewView?.removeFromSuperview()

        currentCenter = coordinate
        currentRadius = radius
        latestTouchPoint = touchPoint

        let view = BulkAddRadiusPreviewView()
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.72, y: 0.72)
        mapView?.addSubview(view)
        previewView = view

        layoutPreview()

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.55,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            view.alpha = 1
            view.transform = .identity
        }
    }

    func move(to coordinate: CLLocationCoordinate2D, touchPoint: CGPoint) {
        currentCenter = coordinate
        latestTouchPoint = touchPoint
        layoutPreview()
        updateEdgePanState()
    }

    func refreshForVisibleRegionChange() {
        layoutPreview()
    }

    func finish(completion: @escaping () -> Void) {
        guard let view = previewView else {
            clear()
            completion()
            return
        }

        stopEdgePan()
        fadeAnimator?.stopAnimation(true)

        let animator = UIViewPropertyAnimator(duration: 0.26, curve: .easeOut) {
            view.alpha = 0
            view.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }

        animator.addCompletion { [weak self, weak view] _ in
            view?.removeFromSuperview()
            self?.clear()
            completion()
        }

        fadeAnimator = animator
        animator.startAnimation()
    }

    func cancel() {
        stopEdgePan()
        fadeAnimator?.stopAnimation(true)
        previewView?.removeFromSuperview()
        clear()
    }

    private func clear() {
        fadeAnimator = nil
        previewView = nil
        currentCenter = nil
        currentRadius = 0
        latestTouchPoint = nil
    }

    private func layoutPreview() {
        guard
            let mapView,
            let previewView,
            let center = currentCenter
        else { return }

        let centerPoint = mapView.convert(center, toPointTo: mapView)
        let edgeCoordinate = coordinate(from: center, eastwardMeters: currentRadius)
        let edgePoint = mapView.convert(edgeCoordinate, toPointTo: mapView)
        let radiusInPoints = max(18, hypot(edgePoint.x - centerPoint.x, edgePoint.y - centerPoint.y))
        let diameter = radiusInPoints * 2

        previewView.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        previewView.center = centerPoint
        previewView.setNeedsLayout()
        updateEdgePanState()
    }

    private func updateEdgePanState() {
        guard edgePanVelocity() != .zero else {
            stopEdgePan()
            return
        }

        guard edgePanDisplayLink == nil else { return }

        let displayLink = CADisplayLink(target: self, selector: #selector(handleEdgePanTick(_:)))
        displayLink.add(to: .main, forMode: .common)
        edgePanDisplayLink = displayLink
    }

    private func stopEdgePan() {
        edgePanDisplayLink?.invalidate()
        edgePanDisplayLink = nil
    }

    @objc private func handleEdgePanTick(_ displayLink: CADisplayLink) {
        guard let mapView else {
            stopEdgePan()
            return
        }

        let velocity = edgePanVelocity()
        guard velocity != .zero else {
            stopEdgePan()
            return
        }

        let visibleCenter = CGPoint(x: mapView.bounds.midX, y: mapView.bounds.midY)
        let nextVisibleCenter = CGPoint(
            x: visibleCenter.x + velocity.x * displayLink.duration,
            y: visibleCenter.y + velocity.y * displayLink.duration
        )
        let nextCenterCoordinate = mapView.convert(nextVisibleCenter, toCoordinateFrom: mapView)

        mapView.setCenter(nextCenterCoordinate, animated: false)

        if let touchPoint = latestTouchPoint {
            currentCenter = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        }

        layoutPreview()
    }

    private func edgePanVelocity() -> CGPoint {
        guard
            let mapView,
            let previewView,
            previewView.superview != nil
        else { return .zero }

        let bounds = mapView.bounds
        let ringFrame = previewView.frame
        let radius = max(1, ringFrame.width / 2)
        let leftPressure = pressure(overflow: bounds.minX - ringFrame.minX, radius: radius)
        let rightPressure = pressure(overflow: ringFrame.maxX - bounds.maxX, radius: radius)
        let topPressure = pressure(overflow: bounds.minY - ringFrame.minY, radius: radius)
        let bottomPressure = pressure(overflow: ringFrame.maxY - bounds.maxY, radius: radius)

        let xVelocity = (rightPressure - leftPressure) * maximumEdgePanSpeed
        let yVelocity = (bottomPressure - topPressure) * maximumEdgePanSpeed

        guard abs(xVelocity) > 0.1 || abs(yVelocity) > 0.1 else { return .zero }
        return CGPoint(x: xVelocity, y: yVelocity)
    }

    private func pressure(overflow: CGFloat, radius: CGFloat) -> CGFloat {
        let startOverflow = radius * edgePanStartOverflowRatio
        let fullSpeedOverflow = max(startOverflow + 1, radius * edgePanFullSpeedOverflowRatio)

        guard overflow > startOverflow else { return 0 }
        return min(1, max(0, (overflow - startOverflow) / (fullSpeedOverflow - startOverflow)))
    }

    private func coordinate(
        from center: CLLocationCoordinate2D,
        eastwardMeters meters: CLLocationDistance
    ) -> CLLocationCoordinate2D {
        let earthRadiusMeters = 6_378_137.0
        let latitudeRadians = center.latitude * .pi / 180
        let longitudeDelta = meters / (earthRadiusMeters * max(cos(latitudeRadians), 0.0001))

        return CLLocationCoordinate2D(
            latitude: center.latitude,
            longitude: center.longitude + longitudeDelta * 180 / .pi
        )
    }
}

private final class BulkAddRadiusPreviewView: UIView {

    private let fillLayer = CAShapeLayer()
    private let strokeLayer = CAShapeLayer()
    private let glowLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        isOpaque = false

        glowLayer.fillColor = UIColor.clear.cgColor
        glowLayer.strokeColor = UIColor.systemMint.withAlphaComponent(0.32).cgColor
        glowLayer.lineWidth = 8
        glowLayer.lineCap = .round
        glowLayer.shadowColor = UIColor.systemMint.cgColor
        glowLayer.shadowOpacity = 0.45
        glowLayer.shadowRadius = 12
        glowLayer.shadowOffset = .zero
        layer.addSublayer(glowLayer)

        fillLayer.fillColor = UIColor.systemMint.withAlphaComponent(0.10).cgColor
        fillLayer.strokeColor = UIColor.clear.cgColor
        layer.addSublayer(fillLayer)

        strokeLayer.fillColor = UIColor.clear.cgColor
        strokeLayer.strokeColor = UIColor.white.withAlphaComponent(0.96).cgColor
        strokeLayer.lineWidth = 3
        strokeLayer.lineDashPattern = [9, 7]
        strokeLayer.lineCap = .round
        layer.addSublayer(strokeLayer)

        addDashAnimation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let ringBounds = bounds.insetBy(dx: 8, dy: 8)
        let path = UIBezierPath(ovalIn: ringBounds).cgPath

        [glowLayer, fillLayer, strokeLayer].forEach { layer in
            layer.frame = bounds
            layer.path = path
        }
    }

    private func addDashAnimation() {
        let animation = CABasicAnimation(keyPath: "lineDashPhase")
        animation.fromValue = 0
        animation.toValue = -16
        animation.duration = 0.9
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        strokeLayer.add(animation, forKey: "bulkAddRadiusDash")
    }
}
