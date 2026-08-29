//
//  SuggestedProspectSheetView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/31/25.
//

import SwiftUI
import MapKit

struct SuggestedProspectBannerView: View {
    let suggestion: Prospect
    var onOpen: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.headline)
                .foregroundColor(.green)
                .frame(width: 28, height: 28)
                .background(Color.green.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("New Recommended Prospect")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(suggestion.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: onOpen) {
                Text("Review")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.green, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.green.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    guard value.translation.height < -24 else { return }
                    onDismiss()
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("New recommended prospect at \(suggestion.address)")
        .accessibilityHint("Tap Review to open details, or swipe up to dismiss")
    }
}

struct SuggestedProspectSheetView: View {
    let suggestion: Prospect
    let nearbyCustomerAddress: String?
    var onAdd: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SuggestedProspectMapPreview(
                suggestionAddress: suggestion.address,
                suggestionCoordinate: suggestion.coordinate,
                nearbyCustomerAddress: nearbyCustomerAddress
            )
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.top, 18)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("New Recommended Prospect")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(suggestion.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    RecommendationSignalView(
                        icon: "location.fill",
                        title: "Nearby",
                        detail: nearbyCustomerAddress == nil ? "Close to a customer" : "Next to a customer"
                    )

                    RecommendationSignalView(
                        icon: "figure.walk",
                        title: "Route fit",
                        detail: "Easy next knock"
                    )
                }

                if let nearbyCustomerAddress {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nearby customer")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(nearbyCustomerAddress)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack(spacing: 12) {
                    Button(action: addSuggestion) {
                        Label("Add Prospect", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: dismissSuggestion) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(width: 48, height: 48)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss recommendation")
                }
            }
            .padding(20)
        }
        .presentationDetents([.fraction(0.5), .fraction(0.68)])
        .presentationDragIndicator(.visible)
    }

    private func addSuggestion() {
        ContactScreenHapticsController.shared.successConfirmationTap()
        ContactScreenSoundController.shared.playSound1()
        onAdd()
    }

    private func dismissSuggestion() {
        ContactScreenHapticsController.shared.lightTap()
        ContactScreenSoundController.shared.playSound1()
        onDismiss()
    }
}

private struct RecommendationSignalView: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)

                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SuggestedProspectMapPreview: View {
    let suggestionAddress: String
    let suggestionCoordinate: CLLocationCoordinate2D?
    let nearbyCustomerAddress: String?

    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
            latitudinalMeters: 1200,
            longitudinalMeters: 1200
        )
    )
    @State private var suggestedCoordinate: CLLocationCoordinate2D?
    @State private var nearbyCustomerCoordinate: CLLocationCoordinate2D?

    var body: some View {
        Map(position: $position) {
            if let nearbyCustomerCoordinate {
                Annotation("Customer", coordinate: nearbyCustomerCoordinate, anchor: .bottom) {
                    VStack(spacing: 3) {
                        Image(systemName: "house.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(Color.white, in: Circle())

                        Text("Customer")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
            }

            if let suggestedCoordinate {
                Annotation("Recommended prospect", coordinate: suggestedCoordinate, anchor: .bottom) {
                    VStack(spacing: 3) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                            .background(Color.white, in: Circle())
                            .shadow(radius: 2)

                        Text("Prospect")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .bottomLeading) {
            Text("Recommended neighbor route")
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.regularMaterial, in: Capsule())
                .padding(10)
        }
        .task(id: suggestionAddress + (nearbyCustomerAddress ?? "")) {
            await loadCoordinates()
        }
    }

    @MainActor
    private func loadCoordinates() async {
        suggestedCoordinate = await coordinate(for: suggestionAddress, fallback: suggestionCoordinate)
        nearbyCustomerCoordinate = await coordinate(for: nearbyCustomerAddress, fallback: nil)
        updateCamera()
    }

    private func coordinate(for address: String?, fallback: CLLocationCoordinate2D?) async -> CLLocationCoordinate2D? {
        if let fallback { return fallback }
        guard let address, let request = MKGeocodingRequest(addressString: address) else { return nil }

        do {
            return try await request.mapItems.first?.location.coordinate
        } catch {
            return nil
        }
    }

    @MainActor
    private func updateCamera() {
        let coordinates = [suggestedCoordinate, nearbyCustomerCoordinate].compactMap { $0 }
        guard let first = coordinates.first else { return }

        guard coordinates.count > 1 else {
            position = .region(
                MKCoordinateRegion(
                    center: first,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
            )
            return
        }

        let minLatitude = coordinates.map(\.latitude).min() ?? first.latitude
        let maxLatitude = coordinates.map(\.latitude).max() ?? first.latitude
        let minLongitude = coordinates.map(\.longitude).min() ?? first.longitude
        let maxLongitude = coordinates.map(\.longitude).max() ?? first.longitude
        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let latitudeMeters = max(450, (maxLatitude - minLatitude) * 111_000 * 2.4)
        let longitudeMeters = max(450, (maxLongitude - minLongitude) * 85_000 * 2.4)

        position = .region(
            MKCoordinateRegion(
                center: center,
                latitudinalMeters: latitudeMeters,
                longitudinalMeters: longitudeMeters
            )
        )
    }
}
