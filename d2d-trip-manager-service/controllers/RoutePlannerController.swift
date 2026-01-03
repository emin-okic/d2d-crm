//
//  RoutePlannerController.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/16/25.
//

import Foundation
import MapKit
import CoreLocation
import SwiftData
import SwiftUI

/// Plans and launches multi-stop follow-up routes for Apple Maps.
enum RoutePlannerController {

    // MARK: Entry point for Today's Appointments
    /// Plans a route for today's *upcoming* appointments and opens in Apple Maps.
    /// Also logs a Trip with total routed miles.
    @MainActor
    static func planAndOpenTodaysRoute(
        appointments: [Appointment],
        modelContext: ModelContext
    ) async {
        let now = Date()
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)

        // Take only TODAY + UPCOMING, keep chronological order
        let todaysUpcoming = appointments
            .filter { cal.isDate($0.date, inSameDayAs: today) && $0.date >= now }
            .sorted { $0.date < $1.date }

        guard !todaysUpcoming.isEmpty else { return }

        // Pull plain address strings in time order (prefer prospect.address, else appointment.location)
        var addresses = todaysUpcoming.compactMap { appt -> String? in
            let a = (appt.prospect?.address.isEmpty == false ? appt.prospect?.address : appt.location) ?? ""
            return a.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : a
        }

        // Optional: de-dupe consecutive duplicates to avoid repeated waypoints
        addresses = Array(LinkedHashSet(addresses))
        guard !addresses.isEmpty else { return }

        // Open in Apple Maps with Current Location -> addr1 -> addr2 -> ...
        openAppleMapsMultiStop(addresses: addresses)
    }
    
    @MainActor
    static func planAndOpenRoute(
        appointments: [Appointment],
        modelContext: ModelContext
    ) async {
        guard !appointments.isEmpty else { return }

        let sorted = appointments.sorted { $0.date < $1.date }

        var addresses = sorted.compactMap { appt -> String? in
            let addr = (appt.prospect?.address.isEmpty == false
                        ? appt.prospect?.address
                        : appt.location) ?? ""
            return addr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : addr
        }

        addresses = Array(LinkedHashSet(addresses))
        guard !addresses.isEmpty else { return }

        openAppleMapsMultiStop(addresses: addresses)
    }

    // MARK: Helpers

    /// Greedy nearest-neighbor ordering from a start coordinate.
    private static func nearestNeighborOrder(start: CLLocationCoordinate2D?, items: [MKMapItem]) -> [MKMapItem] {
        guard !items.isEmpty else { return [] }

        var remaining = items
        var route: [MKMapItem] = []

        var currentCoord: CLLocationCoordinate2D
        
        // In nearestNeighborOrder, replace the "start == nil" branch with:
        if let s = start {
            currentCoord = s
        } else {
            let first = remaining.removeFirst()
            currentCoord = first.placemark.coordinate
            route.append(first)
        }

        while !remaining.isEmpty {
            let nextIndex = nearestIndex(from: currentCoord, in: remaining)
            let next = remaining.remove(at: nextIndex)
            route.append(next)
            currentCoord = next.placemark.coordinate
        }
        return route
    }

    private static func nearestIndex(from coord: CLLocationCoordinate2D, in items: [MKMapItem]) -> Int {
        var bestIdx = 0
        var bestDist = Double.greatestFiniteMagnitude
        let here = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

        for (i, item) in items.enumerated() {
            let there = CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
            let d = here.distance(from: there)
            if d < bestDist {
                bestDist = d
                bestIdx = i
            }
        }
        return bestIdx
    }

    private static func openInAppleMaps(start: MKMapItem?, orderedStops: [MKMapItem]) {
        guard !orderedStops.isEmpty else { return }

        // Build: maps://?dirflg=d&saddr=Current+Location&daddr=addr1&daddr=addr2...
        // (Multiple daddr params are honored by Apple Maps.)
        let encode: (String) -> String = {
            $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0
        }

        let saddr = "Current Location" // always start from current location
        var urlString = "maps://?dirflg=d&saddr=\(encode(saddr))"

        // Hard cap to keep URLs sane; bump if you like
        let maxStops = 12
        let trimmedStops = Array(orderedStops.prefix(maxStops))

        for stop in trimmedStops {
            let addr = readableAddress(for: stop, fallback: "Stop")
            urlString.append("&daddr=\(encode(addr))")
        }

        // Try maps:// first (launches the app directly); fall back to http://
        func tryOpen(_ raw: String) -> Bool {
            guard let url = URL(string: raw) else { return false }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return true
        }

        if !tryOpen(urlString) {
            let httpURL = urlString.replacingOccurrences(of: "maps://", with: "http://maps.apple.com/")
            _ = tryOpen(httpURL)
        }
    }
    
    private static func openAppleMapsMultiStop(addresses: [String]) {
        // Build: maps://?dirflg=d&saddr=Current+Location&daddr=addr1&daddr=addr2&...
        // (Multiple daddr params are supported by Apple Maps.)
        let encode: (String) -> String = {
            $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0
        }

        var url = "maps://?dirflg=d&saddr=\(encode("Current Location"))"

        // Keep it simple; cap stops if you like (Apple Maps handles many, but URLs shouldn’t be huge)
        let maxStops = 12
        for addr in addresses.prefix(maxStops) {
            url += "&daddr=\(encode(addr))"
        }

        // Try native scheme first; fall back to HTTP if needed (Simulator quirks, etc.)
        func open(_ raw: String) {
            if let u = URL(string: raw) {
                UIApplication.shared.open(u, options: [:], completionHandler: nil)
            }
        }

        open(url)
        // Fallback if the first doesn't trigger for some environments
        if url.hasPrefix("maps://") {
            let httpURL = url.replacingOccurrences(of: "maps://", with: "http://maps.apple.com/")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { open(httpURL) }
        }
    }

    private static func readableAddress(for item: MKMapItem?, fallback: String) -> String {
        guard let item = item else { return fallback }
        let pm = item.placemark
        if let name = pm.name, !name.isEmpty { return name }
        // Simple join for common parts
        let parts = [pm.subThoroughfare, pm.thoroughfare, pm.locality, pm.administrativeArea]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? fallback : parts.joined(separator: " ")
    }

    @MainActor
    private static func geocode(_ addresses: [String]) async -> [CLPlacemark] {
        await withTaskGroup(of: CLPlacemark?.self) { group in
            for addr in addresses {
                group.addTask { @Sendable in
                    do {
                        // Create a NEW geocoder inside the task
                        let geocoder = CLGeocoder()
                        let results = try await geocoder.geocodeAddressString(addr)
                        return results.first
                    } catch {
                        print("❌ Geocode failed for \(addr): \(error.localizedDescription)")
                        return nil
                    }
                }
            }

            var output: [CLPlacemark] = []
            for await pm in group {
                if let pm { output.append(pm) }
            }
            return output
        }
    }
}

/// Simple ordered set preserving insertion.
fileprivate struct LinkedHashSet<Element: Hashable>: Sequence {
    private var set = Set<Element>()
    private var array: [Element] = []

    init<S: Sequence>(_ seq: S) where S.Element == Element {
        for e in seq where !set.contains(e) {
            set.insert(e)
            array.append(e)
        }
    }
    func makeIterator() -> IndexingIterator<[Element]> { array.makeIterator() }
}
