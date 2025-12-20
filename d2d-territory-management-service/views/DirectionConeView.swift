//
//  DirectionConeView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/20/25.
//

import UIKit
import CoreLocation

final class DirectionConeView: UIView {

    private let coneLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.addSublayer(coneLayer)
        updatePath()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePath()
    }

    private func updatePath() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let path = UIBezierPath()
        path.move(to: center)
        path.addArc(
            withCenter: center,
            radius: 20,
            startAngle: -.pi / 8,
            endAngle: .pi / 8,
            clockwise: true
        )
        path.close()

        coneLayer.path = path.cgPath
        coneLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.25).cgColor
    }

    func updateHeading(_ degrees: CLLocationDirection) {
        let radians = CGFloat(degrees) * .pi / 180
        transform = CGAffineTransform(rotationAngle: radians)
    }
}
