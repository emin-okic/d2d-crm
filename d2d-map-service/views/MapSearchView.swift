//
//  MapSearchView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UniformTypeIdentifiers   // for .commaSeparatedText
import SwiftData

struct MapSearchView: View {
    // These are bindings passed in from ContentView (or wherever).
    @Binding var region: MKCoordinateRegion
    
    @Query private var prospects: [Prospect]
    
    @Binding var selectedList: String   // ← whatever filter you’re using
    
    let userEmail: String

    // We keep a controller for map logic… (details omitted)
    @StateObject private var controller: MapController

    // This is the text in the search box:
    @State private var searchText: String = ""

    // MARK: – NEW STATE PROPERTIES FOR INTERACTIVE TAP
    /// When you tap a marker, we store its address here…
    @State private var pendingAddress: String? = nil
    /// …and show an alert with “Answered / Not Answered”:
    @State private var showOutcomePrompt = false
    
    @Environment(\.modelContext) private var modelContext
    
    init(region: Binding<MKCoordinateRegion>,
         selectedList: Binding<String>,
         userEmail: String) {
        _region = region
        _selectedList = selectedList
        self.userEmail = userEmail
        _controller = StateObject(wrappedValue: MapController(region: region.wrappedValue))

        // ✅ Add this
        _prospects = Query(filter: #Predicate<Prospect> { $0.userEmail == userEmail })
    }

    var body: some View {
        VStack(spacing: 0) {
            // ──────────────────────────────────────────────────────────────────
            // 1) THE MAP WITH TAPPABLE ANNOTATIONS
            // ──────────────────────────────────────────────────────────────────
            Map(coordinateRegion: $controller.region,
                 annotationItems: controller.markers) { place in

                MapAnnotation(coordinate: place.location) {
                    Circle()
                        .fill(place.markerColor)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                        .contentShape(Rectangle()) // defines tappable area
                        .onTapGesture {
                            pendingAddress = place.address
                            showOutcomePrompt = true
                        }
                        .allowsHitTesting(true)
                        .onTapGesture {
                            print("Tapped marker at \(place.address)")
                            pendingAddress = place.address
                            showOutcomePrompt = true
                        }
                }
            }

            .frame(maxHeight: .infinity)
            .edgesIgnoringSafeArea(.horizontal)

            // ──────────────────────────────────────────────────────────────────
            // 2) SEARCH BAR (unchanged)
            // ──────────────────────────────────────────────────────────────────
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Enter a knock here…", text: $searchText, onCommit: {
                        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        handleSearch(query: trimmed)
                    })
                    .foregroundColor(.primary)
                    .autocapitalization(.words)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 3, x: 0, y: 2)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Spacer()
        }
        // ──────────────────────────────────────────────────────────────────
        // 3) LIFECYCLE / UPDATE MARKERS WHEN PROSPECTS OR SELECTED LIST CHANGES
        // ──────────────────────────────────────────────────────────────────
        .onAppear {
            let filtered = prospects.filter { $0.list == selectedList }
            controller.setMarkers(for: filtered)
        }
        .onChange(of: prospects) { newProspects in
            let filtered = newProspects.filter { $0.list == selectedList }
            controller.setMarkers(for: filtered)
        }
        .onChange(of: selectedList) { newList in
            let filtered = prospects.filter { $0.list == newList }
            controller.setMarkers(for: filtered)
        }
        .onTapGesture {
            // Dismiss keyboard if you tap outside
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
        // ──────────────────────────────────────────────────────────────────
        // 4) ALERT TO CHOOSE “Answered” OR “Not Answered”
        // ──────────────────────────────────────────────────────────────────
        .alert("Knock Outcome",
               isPresented: $showOutcomePrompt,
               actions: {
            Button("Answered") {
                // User tapped “Answered”
                if let addr = pendingAddress {
                    saveKnock(address: addr, status: "Answered")
                }
            }
            Button("Not Answered") {
                // User tapped “Not Answered”
                if let addr = pendingAddress {
                    saveKnock(address: addr, status: "Not Answered")
                }
            }
            Button("Cancel", role: .cancel) {
                // Nothing to do here
            }
        },
               message: {
            Text("Did someone answer at \(pendingAddress ?? "this address")?")
        }
        )
    }

    // Called when the user types something into the search bar and hits Return.
    private func handleSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Instead of geocoding immediately, first ask the user if they want to log “Answered/Not Answered”
        pendingAddress = trimmed
        showOutcomePrompt = true
    }

    // Update your `prospects` array (and the MapController) once the user picks “Answered” / “Not Answered”:
    private func saveKnock(address: String, status: String) {
        let normalized = address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let location = LocationManager.shared.currentLocation

        let lat = location?.latitude ?? 0.0
        let lon = location?.longitude ?? 0.0

        var prospectId: Int64?

        if let existing = prospects.first(where: {
            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }) {
            existing.count += 1
            existing.knockHistory.append(Knock(date: now, status: status, latitude: lat, longitude: lon, userEmail: userEmail))
        } else {
            let newProspect = Prospect(
                fullName: "New Prospect",
                address: address,
                count: 1,
                list: "Prospects",
                userEmail: userEmail
            )
            newProspect.knockHistory = [Knock(date: now, status: status, latitude: lat, longitude: lon, userEmail: userEmail)]
            modelContext.insert(newProspect)

            // Insert to DB and get row ID
            if let newId = DatabaseController.shared.addProspect(name: newProspect.fullName, addr: newProspect.address) {
                prospectId = newId
            }
        }

        if let id = prospectId {
            DatabaseController.shared.addKnock(for: id, date: now, status: status, latitude: lat, longitude: lon, userEmailValue: userEmail)
        }

        controller.performSearch(query: address)
    }
}
