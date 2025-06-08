//
//  MapSearchView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UniformTypeIdentifiers
import SwiftData

/// A view that displays a map with prospect markers and a search bar for logging door knocks.
///
/// Tapping a marker allows the user to record a knock outcome ("Answered" or "Not Answered").
/// New addresses entered in the search bar also trigger this prompt.
struct MapSearchView: View {
    // MARK: - Dependencies

    /// The currently visible map region, bound to the parent.
    @Binding var region: MKCoordinateRegion

    /// The list of all prospects filtered by user.
    @Query private var prospects: [Prospect]

    /// The selected list/category filter (e.g., "Prospects" or "Customers").
    @Binding var selectedList: String

    /// The current user's email (used to scope data).
    let userEmail: String

    /// Controller to manage map logic and annotations.
    @StateObject private var controller: MapController

    // MARK: - Local State

    /// The search field text input.
    @State private var searchText: String = ""

    /// Holds the address tapped or entered before choosing an outcome.
    @State private var pendingAddress: String? = nil

    /// Controls whether the knock outcome prompt is visible.
    @State private var showOutcomePrompt = false

    /// SwiftData context for model updates.
    @Environment(\.modelContext) private var modelContext
    
    @State private var showNoteInput = false
    @State private var newNoteText = ""
    @State private var prospectToNote: Prospect? = nil

    // MARK: - Init

    init(region: Binding<MKCoordinateRegion>,
         selectedList: Binding<String>,
         userEmail: String) {
        _region = region
        _selectedList = selectedList
        self.userEmail = userEmail
        _controller = StateObject(wrappedValue: MapController(region: region.wrappedValue))
        _prospects = Query(filter: #Predicate<Prospect> { $0.userEmail == userEmail })
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Map with markers
            Map(coordinateRegion: $controller.region,
                annotationItems: controller.markers) { place in
                MapAnnotation(coordinate: place.location) {
                    Circle()
                        .fill(place.markerColor)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                        .contentShape(Rectangle()) // Ensures full tap target
                        .onTapGesture {
                            pendingAddress = place.address
                            showOutcomePrompt = true
                        }
                }
            }
            .frame(maxHeight: .infinity)
            .edgesIgnoringSafeArea(.horizontal)

            // MARK: Search bar
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
        // MARK: Map Marker Updates
        .onAppear {
            updateMarkers()
        }
        .onChange(of: prospects) { _ in updateMarkers() }
        .onChange(of: selectedList) { _ in updateMarkers() }

        // Dismisses keyboard when tapping outside
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }

        // MARK: Knock Outcome Prompt
        .alert("Knock Outcome",
               isPresented: $showOutcomePrompt,
               actions: {
            Button("Answered") {
                handleKnockAndPromptNote(status: "Answered")
            }
            Button("Not Answered") {
                handleKnockAndPromptNote(status: "Not Answered")
            }
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("Did someone answer at \(pendingAddress ?? "this address")?")
        })
        .sheet(isPresented: $showNoteInput) {
            NavigationView {
                Form {
                    Section(header: Text("Note Details")) {
                        TextEditor(text: $newNoteText)
                            .frame(minHeight: 100)
                            .padding(.vertical, 4)
                    }

                    Section {
                        Button("Save Note") {
                            if let prospect = prospectToNote {
                                let note = Note(content: newNoteText, authorEmail: userEmail)
                                prospect.notes.append(note)
                                try? modelContext.save()
                            }
                            newNoteText = ""
                            showNoteInput = false
                        }
                        .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .navigationTitle("New Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            newNoteText = ""
                            showNoteInput = false
                        }
                    }
                }
            }
            .tint(.accentColor) // Use system accent
        }
    }

    // MARK: - Methods

    /// Updates the visible map markers based on the current list and user scope.
    private func updateMarkers() {
        let filtered = prospects.filter { $0.list == selectedList }
        controller.setMarkers(for: filtered)
    }

    /// Triggers the outcome prompt when a user types an address into the search bar.
    private func handleSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pendingAddress = trimmed
        showOutcomePrompt = true
    }

    /// Saves a knock for the given address and outcome status. Adds a new prospect if necessary.
    @discardableResult
    private func saveKnock(address: String, status: String) -> Prospect {
        let normalized = address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let location = LocationManager.shared.currentLocation
        let lat = location?.latitude ?? 0.0
        let lon = location?.longitude ?? 0.0

        var prospectId: Int64?
        var updatedProspect: Prospect

        if let existing = prospects.first(where: {
            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }) {
            existing.count += 1
            existing.knockHistory.append(
                Knock(date: now, status: status, latitude: lat, longitude: lon, userEmail: userEmail)
            )
            updatedProspect = existing
        } else {
            let newProspect = Prospect(
                fullName: "New Prospect",
                address: address,
                count: 1,
                list: "Prospects",
                userEmail: userEmail
            )
            newProspect.knockHistory = [
                Knock(date: now, status: status, latitude: lat, longitude: lon, userEmail: userEmail)
            ]
            modelContext.insert(newProspect)
            updatedProspect = newProspect

            if let newId = DatabaseController.shared.addProspect(name: newProspect.fullName, addr: newProspect.address) {
                prospectId = newId
            }
        }

        if let id = prospectId {
            DatabaseController.shared.addKnock(
                for: id,
                date: now,
                status: status,
                latitude: lat,
                longitude: lon,
                userEmailValue: userEmail
            )
        }

        controller.performSearch(query: address)
        try? modelContext.save()

        return updatedProspect
    }
    
    private func handleKnockAndPromptNote(status: String) {
        if let addr = pendingAddress {
            let prospect = saveKnock(address: addr, status: status)
            prospectToNote = prospect
            showNoteInput = true
        }
    }
}
