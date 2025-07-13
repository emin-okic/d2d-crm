//
//  MapSearchView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//
import SwiftUI
import MapKit
import CoreLocation
import SwiftData

struct MapSearchView: View {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedList: String
    @Binding var addressToCenter: String?

    @Query private var prospects: [Prospect]
    @Query private var customers: [Customer]

    @StateObject private var controller: MapController
    @State private var searchText: String = ""
    @State private var pendingAddress: String?
    @State private var showOutcomePrompt = false
    @State private var showNoteInput = false
    @State private var newNoteText = ""
    @State private var prospectToNote: Prospect?
    
    @State private var showObjectionPicker = false
    @State private var objectionOptions: [Objection] = []
    @State private var selectedObjection: Objection?
    @Query private var objections: [Objection]
    
    @State private var showConversionSheet = false
    @State private var prospectToConvert: Prospect?
    
    @State private var showTripPrompt = false
    @State private var showTripPopup = false
    
    @State private var showFollowUpSheet = false
    @State private var followUpAddress: String = ""
    @State private var followUpProspectName: String = ""
    @State private var showFollowUpPrompt = false
    
    @State private var shouldAskForTripAfterFollowUp = false
    
    @StateObject private var tapManager = MapTapAddressManager()
    
    @State private var showingAddObjection = false
    
    private var hasSignedUp: Bool {
        prospects
            .flatMap { $0.knockHistory }
            .contains { $0.status == "Signed Up" }
    }
    
    private var totalKnocks: Int {
        prospects.flatMap { $0.knockHistory }.count
    }

    @Environment(\.modelContext) private var modelContext
    
    private var averageKnocksPerCustomer: Int {
        let customerKnocks = prospects
            .filter { $0.list == "Customers" }
            .map { $0.knockHistory.count }
        guard !customerKnocks.isEmpty else { return 0 }
        return Int(Double(customerKnocks.reduce(0, +)) / Double(customerKnocks.count))
    }

    init(region: Binding<MKCoordinateRegion>,
         selectedList: Binding<String>,
         addressToCenter: Binding<String?>) {
        _region = region
        _selectedList = selectedList
        _addressToCenter = addressToCenter
        _controller = StateObject(wrappedValue: MapController(region: region.wrappedValue))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                
                Map(coordinateRegion: $controller.region, annotationItems: controller.markers) { place in
                    MapAnnotation(coordinate: place.location) {
                        if place.list == "Customers" {
                            Image(systemName: "star.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    pendingAddress = place.address
                                    showOutcomePrompt = true
                                }
                        } else {
                            Circle()
                                .fill(place.markerColor)
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    pendingAddress = place.address
                                    showOutcomePrompt = true
                                }
                        }
                    }
                }
                .gesture(
                    TapGesture()
                        .onEnded {
                            let center = controller.region.center
                            tapManager.handleTap(at: center)

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                let tapped = tapManager.tappedAddress
                                if prospectExists(at: tapped) {
                                    pendingAddress = tapped
                                    showOutcomePrompt = true
                                }
                            }
                        }
                )
                .frame(maxHeight: .infinity)
                .edgesIgnoringSafeArea(.horizontal)

                Spacer()
            }
            
            HStack(spacing: 12) {
                RejectionTrackerView(count: totalKnocks)
                
                if hasSignedUp {
                    KnocksPerSaleView(count: averageKnocksPerCustomer, hasFirstSignup: true)
                }
            }
            .cornerRadius(16)
            .shadow(radius: 4)
            .padding(.top, 10)
            .frame(maxWidth: .infinity, alignment: .center)
            .zIndex(1) // Make sure it stays on top
            
            VStack {
                Spacer()
                
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
                .padding(.horizontal)
                .padding(.bottom, 56) // Adjust this to float higher or lower
            }
            
        }
        .onAppear { updateMarkers() }
        .onChange(of: prospects) { _ in updateMarkers() }
        .onChange(of: selectedList) { _ in updateMarkers() }
        .onChange(of: addressToCenter) { newAddress in
            if let query = newAddress {
                Task {
                    if let coordinate = await controller.geocodeAddress(query) {
                        withAnimation {
                            controller.region = MKCoordinateRegion(
                                center: coordinate,
                                latitudinalMeters: 1609.34,
                                longitudinalMeters: 1609.34
                            )
                        }
                    }
                    addressToCenter = nil
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
        }
        .alert("Add This Prospect?", isPresented: $tapManager.showAddPrompt, actions: {
            Button("Yes") {
                pendingAddress = tapManager.tappedAddress
                // Force a marker update and simulate tapping on a new prospect marker
                let _ = saveKnock(address: tapManager.tappedAddress, status: "Not Answered")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showOutcomePrompt = true
                }
            }
            Button("No", role: .cancel) {}
        }, message: {
            Text("Do you want to add \(tapManager.tappedAddress)?")
        })
        .alert("Knock Outcome", isPresented: $showOutcomePrompt, actions: {
            
            Button("Signed Up") {
                handleKnockAndConvertToCustomer(status: "Signed Up")
            }
            
            Button("Not Answered") { handleKnockAndPromptNote(status: "Not Answered") }
            
            Button("Not Enough Interest") { handleKnockAndPromptObjection(status: "Not Enough Interest") }
            
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("Did someone answer at \(pendingAddress ?? "this address")?")
        })
        .sheet(isPresented: $showObjectionPicker) {
            NavigationView {
                List(objectionOptions) { obj in
                    Button(action: {
                        selectedObjection = obj
                        obj.timesHeard += 1
                        try? modelContext.save()
                        showObjectionPicker = false
                        showNoteInput = true
                    }) {
                        VStack(alignment: .leading) {
                            Text(obj.text)
                                .font(.headline)
                            if !obj.response.isEmpty {
                                Text(obj.response)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Why not interested?")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showObjectionPicker = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddObjection) {
            AddObjectionView()
        }
        .sheet(isPresented: $showConversionSheet) {
            if let prospect = prospectToConvert {
                SignUpPopupView(prospect: prospect, isPresented: $showConversionSheet)
            }
        }
        .alert("Schedule Follow-Up?", isPresented: $showFollowUpPrompt) {
            Button("Yes") {
                shouldAskForTripAfterFollowUp = true
                showFollowUpSheet = true
            }
            Button("No", role: .cancel) {
                showTripPrompt = true
            }
        } message: {
            Text("Would you like to schedule a follow-up for \(followUpProspectName)?")
        }
        .sheet(isPresented: $showFollowUpSheet) {
            FollowUpScheduleView(address: followUpAddress, prospectName: followUpProspectName)
        }
        .alert("Do you want to log a trip?", isPresented: $showTripPrompt) {
            Button("Yes") { showTripPopup = true }
            Button("No", role: .cancel) {}
        }
        .sheet(isPresented: $showTripPopup) {
            if let addr = pendingAddress {
                LogTripPopupView(endAddress: addr)
            }
        }
        .sheet(isPresented: $showNoteInput) {
            if let prospect = prospectToNote {
                LogNoteView(
                    prospect: prospect,
                    objection: selectedObjection,
                    pendingAddress: pendingAddress,
                    onComplete: {
                        followUpAddress = prospect.address
                        followUpProspectName = prospect.fullName
                        selectedObjection = nil
                        showFollowUpPrompt = true
                    }
                )
            }
        }
        .onChange(of: showFollowUpSheet) { isShowing in
            if !isShowing && showFollowUpPrompt {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showTripPrompt = true
                }
            }
        }
        .onChange(of: showFollowUpSheet) { isShowing in
            if !isShowing && shouldAskForTripAfterFollowUp {
                shouldAskForTripAfterFollowUp = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showTripPrompt = true
                }
            }
        }
    }
    
    private var totalRejectionsSinceLastSignup: Int {
        let allKnocks = prospects.flatMap { $0.knockHistory }
            .sorted(by: { $0.date > $1.date })

        var count = 0
        for knock in allKnocks {
            if knock.status == "Signed Up" { break }
            if knock.status == "Not Answered" || knock.status == "Not Enough Interest" {
                count += 1
            }
        }
        return count
    }
    
    private func prospectExists(at address: String) -> Bool {
        let normalized = address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return prospects.contains { $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized } ||
               customers.contains { $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized }
    }

    private func updateMarkers() {
        controller.setMarkers(prospects: prospects, customers: customers)
    }

    private func handleSearch(query: String) {
        pendingAddress = query
        showOutcomePrompt = true
    }

    private func saveKnock(address: String, status: String) -> Prospect {
        let normalized = address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let location = LocationManager.shared.currentLocation
        let lat = location?.latitude ?? 0.0
        let lon = location?.longitude ?? 0.0

        var prospectId: Int64?
        var updated: Prospect

        if let existing = prospects.first(where: {
            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }) {
            existing.count += 1
            existing.knockHistory.append(Knock(date: now, status: status, latitude: lat, longitude: lon))
            updated = existing
        } else {
            let new = Prospect(fullName: "New Prospect", address: address, count: 1, list: "Prospects")
            new.knockHistory = [Knock(date: now, status: status, latitude: lat, longitude: lon)]
            modelContext.insert(new)
            updated = new

            if let newId = DatabaseController.shared.addProspect(name: new.fullName, addr: new.address) {
                prospectId = newId
            }
        }

        if let id = prospectId {
            DatabaseController.shared.addKnock(for: id, date: now, status: status, latitude: lat, longitude: lon)
        }

        controller.performSearch(query: address)
        try? modelContext.save()
        return updated
    }

    private func handleKnockAndPromptNote(status: String) {
        if let addr = pendingAddress {
            let prospect = saveKnock(address: addr, status: status)

            // Only show note popup for statuses other than "Not Answered"
            if status != "Not Answered" {
                prospectToNote = prospect
                showNoteInput = true
            } else {
                // Optionally prompt to log a trip even if no note is added
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showTripPrompt = true
                }
            }
        }
    }
    
    private func handleKnockAndPromptObjection(status: String) {
        guard let addr = pendingAddress else { return }

        let prospect = saveKnock(address: addr, status: status)
        prospectToNote = prospect

        if objections.isEmpty {
            // Redirect user to create a new objection before proceeding
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectedObjection = nil
                showNoteInput = false
                showingAddObjection = true  // <-- triggers AddObjectionView sheet
            }
        } else {
            objectionOptions = objections
            showObjectionPicker = true
        }
    }
    
    private func handleKnockAndConvertToCustomer(status: String) {
        guard let addr = pendingAddress else { return }
        let prospect = saveKnock(address: addr, status: status)
        prospectToConvert = prospect
        showConversionSheet = true
    }
}
