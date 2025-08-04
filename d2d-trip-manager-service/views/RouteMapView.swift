//
//  RouteMapView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/20/25.
//


import SwiftUI
import MapKit

struct RouteMapView: UIViewRepresentable {
    let startAddress: String
    let endAddress: String

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.isUserInteractionEnabled = false
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        Task {
            let geocoder = CLGeocoder()
            do {
                let startPlacemarks = try await geocoder.geocodeAddressString(startAddress)
                let endPlacemarks = try await geocoder.geocodeAddressString(endAddress)

                guard let startLocation = startPlacemarks.first?.location,
                      let endLocation = endPlacemarks.first?.location else {
                    return
                }

                let startItem = MKMapItem(placemark: MKPlacemark(coordinate: startLocation.coordinate))
                let endItem = MKMapItem(placemark: MKPlacemark(coordinate: endLocation.coordinate))

                let request = MKDirections.Request()
                request.source = startItem
                request.destination = endItem
                request.transportType = .automobile

                let directions = MKDirections(request: request)
                let response = try await directions.calculate()

                if let route = response.routes.first {
                    await MainActor.run {
                        mapView.removeOverlays(mapView.overlays)
                        mapView.addOverlay(route.polyline)
                        mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                                  edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40),
                                                  animated: false)
                    }
                }
            } catch {
                print("Map route error: \(error.localizedDescription)")
            }
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleUIView(_ uiView: MKMapView, coordinator: ()) {
        uiView.removeFromSuperview()
    }
}
