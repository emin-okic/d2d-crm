//
//  MapSearchView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//  Stepper-integrated version (shows KnockStepperPopupView ONLY for Follow-Up Later)
//

import SwiftUI
import MapKit
import CoreLocation
import SwiftData
import Combine
import Contacts

struct MapSearchView: View {
    @Binding var searchText: String
    @Binding var contactSearchText: String
    @Binding var region: MKCoordinateRegion
    @Binding var selectedList: String
    @Binding var addressToCenter: String?

    @Query private var prospects: [Prospect]
    @Query private var customers: [Customer]
    @Query private var objections: [Objection]

    @StateObject private var controller: MapController

    @State private var pendingAddress: String?

    @State private var showConversionSheet = false
    @State private var prospectToConvert: Prospect?

    @StateObject private var tapManager = MapTapAddressManager()
    @StateObject private var searchVM = SearchCompleterViewModel()
    @FocusState private var isSearchFocused: Bool

    @State private var isTappedAddressCustomer = false

    @State private var popupState: PopupState?
    @State private var popupScreenPosition: CGPoint? = nil

    @State private var isSearchExpanded = false
    @Namespace private var animationNamespace

    @Environment(\.modelContext) private var modelContext

    @State private var pendingRecordingFileName: String?

    @AppStorage("recordingModeEnabled") private var recordingModeEnabled: Bool = true
    @AppStorage("studioUnlocked") private var studioUnlocked: Bool = false
    private var recordingFeaturesActive: Bool { studioUnlocked && recordingModeEnabled }

    @State private var prospectKnockingController: ProspectKnockActionController? = nil

    // NEW: Stepper state (only used for Follow-Up Later)
    @State private var stepperState: KnockStepperState? = nil
    
    @State private var showConfetti = false
    @State private var followUpScheduledConfirmation: FollowUpScheduledConfirmation?
    
    @State private var pendingAddProperty: PendingAddProperty?
    
    @StateObject private var userLocationManager = UserLocationManager()
    @State private var previousRegionBeforeUserLocationJump: MKCoordinateRegion?
    
    @State private var selectedPlaceID: UUID? = nil
    @State private var isCustomizingMapScorecards = false
    
    @State private var pendingBulkAdd: PendingBulkAdd?
    
    @State private var selectedUnitGroup: UnitGroup?
    @State private var selectedMultiContactState: MultiContactState?
    @State private var selectedProspect: Prospect?
    @State private var selectedCustomer: Customer?
    @State private var pendingSelectedContact: UnitContact? = nil
    
    init(searchText: Binding<String>,
         contactSearchText: Binding<String>,
         region: Binding<MKCoordinateRegion>,
         selectedList: Binding<String>,
         addressToCenter: Binding<String?>) {
        _searchText = searchText
        _contactSearchText = contactSearchText
        _region = region
        _selectedList = selectedList
        _addressToCenter = addressToCenter
        _controller = StateObject(wrappedValue: MapController(region: region.wrappedValue))
    }

    private var mapMarkers: [IdentifiablePlace] {
        guard let pendingAddProperty else { return controller.markers }

        let previewMarker = IdentifiablePlace(
            id: pendingAddProperty.id,
            address: pendingAddProperty.address,
            location: pendingAddProperty.coordinate,
            count: 0,
            list: "PendingProperty"
        )

        return controller.markers + [previewMarker]
    }

    private var activeContactFilter: String {
        contactSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isContactFilterActive: Bool {
        !activeContactFilter.isEmpty
    }

    private var filteredProspectsForMap: [Prospect] {
        guard isContactFilterActive else { return prospects }
        guard selectedList == "Prospects" else { return [] }
        return prospects.filter { contactMatchesFilter($0) }
    }

    private var filteredCustomersForMap: [Customer] {
        guard isContactFilterActive else { return customers }
        guard selectedList == "Customers" else { return [] }
        return customers.filter { contactMatchesFilter($0) }
    }

    private var filteredMapContactCount: Int {
        filteredProspectsForMap.count + filteredCustomersForMap.count
    }

    private var contactFilterBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Map filtered by Contacts")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("\(selectedList): \(filteredMapContactCount) match\(filteredMapContactCount == 1 ? "" : "es") for \"\(activeContactFilter)\"")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)

            Button {
                clearContactFilter()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear Contact Filter")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: 420)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 5)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {

                MapDisplayView(
                    region: $controller.region,
                    markers: mapMarkers,
                    selectedPlaceID: selectedPlaceID,
                    userLocationManager: userLocationManager,
                    onMarkerTapped: { place in
                        handleMarkerTap(place: place, geo: geo)
                    },
                    onMapTapped: { coordinate in
                        handleMapTap(at: coordinate)
                    },
                    onRegionChange: { newRegion, isUserDriven in
                        handleRegionChange(newRegion, isUserDriven: isUserDriven)
                    }
                )
                .frame(maxHeight: .infinity)
                .edgesIgnoringSafeArea(.horizontal)

                ScorecardBar(isCustomizingScorecards: $isCustomizingMapScorecards)

                FloatingSearchAndMicButtons(
                    searchText: $searchText,
                    isExpanded: $isSearchExpanded,
                    isFocused: $isSearchFocused,
                    viewModel: searchVM,
                    animationNamespace: animationNamespace,
                    onSubmit: { submitSearch() },
                    onSelectResult: { handleCompletionTap($0) },
                    userLocationManager: userLocationManager,
                    mapController: controller,
                    isShowingPreviousRegionButton: previousRegionBeforeUserLocationJump != nil,
                    onNavigateToUserLocation: navigateToUserLocation,
                    onRevertToPreviousRegion: revertToPreviousRegion
                )

                if isContactFilterActive {
                    contactFilterBanner
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 16)
                        .padding(.top, 118)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1200)
                }
                
            }
            
            // This is for the prospect updating marker stuff
            .onChange(of: prospects) { updateMarkers() }
            .onChange(of: customers) { updateMarkers() }
            .onChange(of: selectedList) { updateMarkers() }
            .onChange(of: contactSearchText) { updateMarkers() }
            
            // Prospect Popup Stuff
            .sheet(item: $selectedUnitGroup, onDismiss: resetSelectedMapMarker) { group in
                UnitSelectorPopupView(
                    baseAddress: group.base,
                    units: group.units,
                    onSelect: { unitGroup in
                        selectedUnitGroup = nil
                        openUnitContactGroup(unitGroup, baseAddress: group.base)
                    },
                    onClose: {
                        selectedUnitGroup = nil
                        resetSelectedMapMarker()
                    }
                )
                .presentationDetents([.fraction(0.46)])
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.46)))
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedMultiContactState, onDismiss: resetSelectedMapMarker) { state in
                MultiContactPopupView(
                    state: state,
                    onSelect: { contact in
                        selectedMultiContactState = nil
                        showPopup(for: place(for: contact))
                    },
                    onClose: {
                        selectedMultiContactState = nil
                        resetSelectedMapMarker()
                    }
                )
                .presentationDetents([.fraction(0.42)])
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.42)))
                .presentationDragIndicator(.visible)
            }
            // This is for the contact popup display
            .sheet(item: $popupState, onDismiss: resetSelectedMapMarker) { popup in
                popupSheet(for: popup)
            }
            .sheet(item: $stepperState) { state in
                KnockStepperPopupView(
                        context: state.ctx,
                        objections: objections,
                        saveKnock: { outcome in
                            if state.ctx.isCustomer {
                                let customerController = CustomerKnockActionController(
                                    modelContext: modelContext,
                                    controller: controller
                                )
                                let customer = customerController.saveKnockOnly(
                                    address: state.ctx.address,
                                    status: outcome.rawValue,
                                    customers: customers,
                                    onUpdateMarkers: { updateMarkers() }
                                )
                                let p = Prospect(
                                    fullName: customer.fullName,
                                    address: customer.address,
                                    count: customer.knockCount,
                                    list: "Customers"
                                )
                                p.latitude = customer.latitude
                                p.longitude = customer.longitude
                                return p
                            } else {
                                return prospectKnockingController!.saveKnockOnly(
                                    address: state.ctx.address,
                                    status: outcome.rawValue,
                                    prospects: prospects,
                                    onUpdateMarkers: { updateMarkers() }
                                )
                            }
                        },
                        incrementObjection: { obj in
                            obj.timesHeard += 1
                            if recordingFeaturesActive,
                               let name = pendingRecordingFileName {
                                let rec = Recording(
                                    fileName: name,
                                    title: obj.text,
                                    date: .now,
                                    objection: obj,
                                    rating: 3
                                )
                                modelContext.insert(rec)
                                pendingRecordingFileName = nil
                            }
                            try? modelContext.save()
                        },
                        saveFollowUp: { prospect, date in
                            saveFollowUp(for: state.ctx, prospect: prospect, date: date)
                        },
                        convertToCustomer: { prospect, done in
                            prospectToConvert = prospect
                            showConversionSheet = true
                            done()
                        },
                        addNote: { prospect, text in
                            prospect.notes.append(Note(content: text))
                            try? modelContext.save()
                        },
                        logTrip: { start, end, date in
                            guard !end.isEmpty else { return }
                            let trip = Trip(
                                startAddress: start,
                                endAddress: end,
                                miles: 0,
                                date: date
                            )
                            modelContext.insert(trip)
                            try? modelContext.save()
                        },
                        onClose: { completed in
                            let completedAddress = state.ctx.address
                            stepperState = nil
                            guard completed else { return }
                            showFollowUpScheduledConfirmation(for: completedAddress, in: geo)
                        }
                )
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .presentationDetents([.fraction(0.75), .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.75)))
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showConversionSheet) {
                // TODO: Move out this code in the body to a function for creating customers
                if let prospect = prospectToConvert {
                    CustomerCreateStepperView(
                        initialName: prospect.fullName,
                        initialAddress: prospect.address,
                        initialPhone: prospect.contactPhone,
                        initialEmail: prospect.contactEmail
                    ) { newCustomer in
                        
                        // Carry over history, notes, appointments, coordinates
                        newCustomer.knockHistory = prospect.knockHistory
                        newCustomer.notes = prospect.notes
                        newCustomer.appointments = prospect.appointments
                        
                        newCustomer.phoneCalls = prospect.phoneCalls
                        
                        // ✅ update recipient info
                        for call in newCustomer.phoneCalls {
                            call.recipientUUID = newCustomer.uuid
                            call.recipientType = .customer
                        }
                        
                        newCustomer.emailsSent = prospect.emailsSent
                        
                        for email in newCustomer.emailsSent {
                            email.recipientUUID = newCustomer.uuid
                            email.recipientType = .customer
                        }
                        
                        if newCustomer.contactPhone.isEmpty { newCustomer.contactPhone = prospect.contactPhone }
                        if newCustomer.contactEmail.isEmpty { newCustomer.contactEmail = prospect.contactEmail }
                        newCustomer.latitude = prospect.latitude
                        newCustomer.longitude = prospect.longitude

                        // Persist new customer and delete old prospect
                        modelContext.insert(newCustomer)
                        modelContext.delete(prospect)
                        try? modelContext.save()
                        
                        updateMarkers()
                        selectedList = "Customers"
                        
                        // Celebrate 🎉
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation { showConfetti = true }
                        }
                        
                        showConversionSheet = false
                    } onCancel: {
                        showConversionSheet = false
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            
            //
            // Other Stuff
            //
            // inside body chain where you had the presenter & lifecycle hooks
            
            // Ad related modifiers
            .presentRotatingAdsCentered()
            .onAppear {
                // 🔹 Show exactly one ad for this app session (centered). Will differ each launch.
                AdEngine.shared.startSingleShot(inventory: AdDemoInventory.defaultAds)
            }
            .onDisappear {
                // No-op for single-shot, but keep if you want to explicitly clear.
                AdEngine.shared.stop()
            }
            
            // Search engine related modifiers
            .onChange(of: popupState) { _, newValue in
                // Close the search bar when a popup opens
                if newValue != nil, isSearchExpanded {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearchExpanded = false
                        isSearchFocused = false
                        searchText = ""
                    }
                }
            }
           // Listen for search focus and close popup
            .onChange(of: isSearchFocused) { _, focused in
                if focused {
                    // Close any open popup when the search bar is tapped/focused
                    withAnimation(.easeInOut(duration: 0.2)) {
                        popupState = nil
                    }
                }
            }
            
            // Confetti for conversion and property flows.
            if showConfetti {
                ConfettiBurstView()
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(5000)
                    .onAppear {
                        // Auto dismiss after a few seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showConfetti = false }
                        }
                    }
            }

            if let confirmation = followUpScheduledConfirmation {
                FollowUpScheduledMapConfirmationView(address: confirmation.address)
                    .position(confirmation.position)
                    .allowsHitTesting(false)
                    .transition(.scale(scale: 0.86).combined(with: .opacity))
                    .zIndex(5001)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation(.easeOut(duration: 0.22)) {
                                followUpScheduledConfirmation = nil
                            }
                        }
                    }
            }
            
        }
        
        // Modifier for markers
        .onReceive(NotificationCenter.default.publisher(for: .mapShouldRecenterAllMarkers)) { _ in
            controller.recenterToFitAllMarkers()
            
        }
        .onChange(of: searchText) { _, newValue in searchVM.updateQuery(newValue) }
        .onAppear {
            updateMarkers()
            prospectKnockingController = ProspectKnockActionController(modelContext: modelContext, controller: controller)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: .mapShouldRecenterAllMarkers, object: nil)
                }
            
        }
        .onChange(of: addressToCenter) { _, newValue in handleMapCenterChange(newAddress: newValue) }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil,from:nil,for:nil)
        }
        // This is the menu option for new properties - all else is handled during the popup
        .sheet(item: $pendingAddProperty) { item in
            AddPropertyConfirmationSheet(
                address: item.address,
                coordinate: item.coordinate,
                onConfirm: {
                    pendingAddProperty = nil

                    addProspectFromMapTap(
                        address: item.address,
                        coordinate: item.coordinate
                    )
                    
                    
                    // 🏆 Reward haptic — feels like a win
                    MapScreenHapticsController.shared.propertyAdded()
                    
                    // 🏆 Haptic + sound = reward
                    MapScreenSoundController.shared.playPropertyAdded()
                },
                onCancel: {
                    pendingAddProperty = nil
                }
            )
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
            .onAppear {
                // ✨ Entry sound
                MapScreenSoundController.shared.playPropertyOpen()
            }
        }
        
        // This is for bulk property additions
        .onReceive(NotificationCenter.default.publisher(for: .didRequestBulkAdd)) { note in
            guard let bulk = note.object as? PendingBulkAdd else { return }

            Task { @MainActor in
                var resolved: [PendingAddProperty] = []
                var seenAddresses: Set<String> = [] // Track normalized addresses in this bulk

                for prop in bulk.properties {

                    guard let address = await controller.reverseGeocode(coordinate: prop.coordinate) else {
                        continue
                    }

                    let normalized = address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                    // Skip if address already exists globally
                    let existsGlobally = prospects.contains {
                        $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
                    } || customers.contains {
                        $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
                    }

                    // Skip if duplicate inside this bulk
                    guard !existsGlobally, !seenAddresses.contains(normalized) else { continue }

                    let propertyCoordinate = await controller.geocodeAddress(address) ?? prop.coordinate

                    resolved.append(PendingAddProperty(address: address, coordinate: propertyCoordinate))
                    seenAddresses.insert(normalized)
                }

                pendingBulkAdd = PendingBulkAdd(
                    center: bulk.center,
                    radius: bulk.radius,
                    properties: resolved
                )
            }
        }
        .sheet(item: $pendingBulkAdd) { bulk in
            BulkAddConfirmationSheet(
                bulk: bulk,
                onConfirm: { selected in
                    for prop in selected {
                        addProspectFromMapTap(address: prop.address, coordinate: prop.coordinate)
                    }
                    pendingBulkAdd = nil
                },
                onCancel: {
                    pendingBulkAdd = nil
                }
            )
            .presentationDetents([.fraction(0.5)])
            .presentationDragIndicator(.visible)
            .onAppear {
                // ✨ Entry feedback
                MapScreenHapticsController.shared.mapTap()
                MapScreenSoundController.shared.playPropertyOpen()
            }
        }
        
        // This is for opening the contact details
        .sheet(item: $selectedProspect) { prospect in
            NavigationStack {
                ProspectDetailsView(prospect: prospect)
            }
        }

        .sheet(item: $selectedCustomer) { customer in
            NavigationStack {
                CustomerDetailsView(customer: customer)
            }
        }
    }

    private func handleRegionChange(_ newRegion: MKCoordinateRegion, isUserDriven: Bool) {
        Task { @MainActor in
            await Task.yield()

            if !regionsMatch(controller.region, newRegion) {
                controller.region = newRegion
            }

            if isUserDriven {
                previousRegionBeforeUserLocationJump = nil

                if popupState != nil {
                    popupState = nil
                }
            }
        }
    }

    private func navigateToUserLocation() {
        guard let location = userLocationManager.location else { return }

        previousRegionBeforeUserLocationJump = controller.region
        controller.region.center = location.coordinate
    }

    private func revertToPreviousRegion() {
        guard let previousRegion = previousRegionBeforeUserLocationJump else { return }

        controller.region = previousRegion
        previousRegionBeforeUserLocationJump = nil
    }

    private func regionsMatch(_ lhs: MKCoordinateRegion, _ rhs: MKCoordinateRegion) -> Bool {
        abs(lhs.center.latitude - rhs.center.latitude) <= 0.0001 &&
        abs(lhs.center.longitude - rhs.center.longitude) <= 0.0001 &&
        abs(lhs.span.latitudeDelta - rhs.span.latitudeDelta) <= 0.0001 &&
        abs(lhs.span.longitudeDelta - rhs.span.longitudeDelta) <= 0.0001
    }
    
    private func transferEmailsToProspect(from customer: Customer, to prospect: Prospect) {
        
        // Move email references
        prospect.emailsSent = customer.emailsSent

        // Update ownership metadata
        for email in prospect.emailsSent {
            email.recipientUUID = prospect.uuid
            email.recipientType = .prospect
        }
        
    }
    
    private func handleMarkerTap(place: IdentifiablePlace, geo: GeometryProxy) {
        
        selectedPlaceID = place.id
        
        // 🔹 STEP for Apartment / multi-unit interception
        let parts = parseAddress(place.address)
        let units = unitContactGroupsForBaseAddress(parts.base)

        if units.count > 1 {
            // ✅ Center map on the apartment complex itself
            withAnimation(.easeInOut(duration: 0.35)) {
                controller.centerMapForPopup(coordinate: place.location)
            }
            
            // Show unit selector instead of prospect popup
            selectedUnitGroup = UnitGroup(base: parts.base, units: units)
            return
        }

        if let unitGroup = units.first, unitGroup.contactCount > 1 {
            withAnimation(.easeInOut(duration: 0.35)) {
                controller.centerMapForPopup(coordinate: place.location)
            }

            selectedMultiContactState = MultiContactState(
                baseAddress: parts.base,
                unit: unitGroup.unit,
                contacts: unitGroup.contacts
            )
            return
        }
        
        // Center the map each time a prospect is selected
        withAnimation(.easeInOut(duration: 0.35)) {
            controller.centerMapForPopup(coordinate: place.location)
        }

        if let contact = units.first?.primaryContact {
            presentPopup(for: self.place(for: contact))
        } else {
            presentPopup(for: place)
        }

        if let mapView = MapDisplayView.cachedMapView {
            let raw = mapView.convert(place.location, toPointTo: mapView)
            let popupW: CGFloat = 240
            let halfW = popupW / 2
            let halfH: CGFloat = 60
            let offsetY = halfH + 14
            let x = min(max(raw.x, halfW), geo.size.width - halfW)
            let y = min(max(raw.y - offsetY, halfH), geo.size.height - halfH)
            popupScreenPosition = CGPoint(x: x, y: y)
        }
    }

    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        guard !isCustomizingMapScorecards else { return }

        // 🎯 Haptic: instant response
        MapScreenHapticsController.shared.mapTap()

        if dismissActiveMapPopup() {
            return
        }
        
        // Deselect any currently selected marker
        selectedPlaceID = nil
        
        // CLOSE SEARCH FIRST if click anywhere other than search
        if isSearchExpanded {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearchExpanded = false
                isSearchFocused = false
                searchText = ""
            }
        }
        
        // Register tap in tap manager
        tapManager.handleTap(at: coordinate)

        // Check after a short delay for new address
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let tapped = tapManager.tappedAddress
            guard !tapped.isEmpty else { return }

            // Normalize address for comparison
            let normalized = tapped.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip if address already exists
            let exists = prospects.contains {
                $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalized
            }

            guard !exists else { return }

            presentPendingAddProperty(address: tapped, coordinate: coordinate)
        }
    }

    private func presentPendingAddProperty(address: String, coordinate: CLLocationCoordinate2D) {
        selectedPlaceID = nil
        pendingAddProperty = PendingAddProperty(address: address, coordinate: coordinate)
        controller.centerMapForNewProperty(coordinate: coordinate)
    }

    private func resetSelectedMapMarker() {
        selectedPlaceID = nil

        guard let mapView = MapDisplayView.cachedMapView else { return }

        DispatchQueue.main.async {
            if let coordinator = mapView.delegate as? MapDisplayCoordinator {
                coordinator.updateSelectedPlaceID(nil)
            }

            mapView.selectedAnnotations.forEach {
                mapView.deselectAnnotation($0, animated: false)
            }

            if let coordinator = mapView.delegate as? MapDisplayCoordinator {
                coordinator.refreshAllAnnotations(on: mapView)
            }
        }
    }

    private func dismissActiveMapPopup() -> Bool {
        guard popupState != nil || selectedUnitGroup != nil || selectedMultiContactState != nil else {
            return false
        }

        popupState = nil
        selectedUnitGroup = nil
        selectedMultiContactState = nil
        resetSelectedMapMarker()
        return true
    }

    private func openUnitContactGroup(_ unitGroup: UnitContactGroup, baseAddress: String) {
        if unitGroup.contactCount > 1 {
            DispatchQueue.main.async {
                selectedMultiContactState = MultiContactState(
                    baseAddress: baseAddress,
                    unit: unitGroup.unit,
                    contacts: unitGroup.contacts
                )
            }
            return
        }

        guard let contact = unitGroup.primaryContact else { return }

        DispatchQueue.main.async {
            showPopup(for: place(for: contact))
        }
    }

    private func place(for contact: UnitContact) -> IdentifiablePlace {
        IdentifiablePlace(
            address: contact.address,
            location: contact.coordinate ?? controller.region.center,
            count: contact.knockCount,
            unitCount: 1,
            contactCount: 1,
            list: contact.list,
            isUnqualified: contact.isUnqualified,
            isMultiUnit: false,
            showsMultiContact: false,
            selectedContact: contact
        )
    }

    @ViewBuilder
    private func popupSheet(for popup: PopupState) -> some View {
        if popup.place.list == "Customers" {
            customerPopupSheet(for: popup.place)
        } else {
            prospectPopupSheet(for: popup.place)
        }
    }

    private func customerPopupSheet(for place: IdentifiablePlace) -> some View {
        CustomerPopupView(
            place: place,
            onClose: {
                popupState = nil
                resetSelectedMapMarker()
            },
            onOutcomeSelected: { outcome, fileName in
                handlePopupOutcome(for: place, outcome: outcome, fileName: fileName)
            },
            recordingModeEnabled: recordingModeEnabled,
            onViewDetails: {
                openDetails(for: place)
            }
        )
        .presentationDetents([.fraction(0.34)])
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.34)))
        .presentationDragIndicator(.visible)
    }

    private func prospectPopupSheet(for place: IdentifiablePlace) -> some View {
        ProspectPopupView(
            place: place,
            isCustomer: false,
            onClose: {
                popupState = nil
                resetSelectedMapMarker()
            },
            onOutcomeSelected: { outcome, fileName in
                handlePopupOutcome(for: place, outcome: outcome, fileName: fileName)
            },
            recordingModeEnabled: recordingModeEnabled,
            onViewDetails: {
                openDetails(for: place)
            }
        )
        .presentationDetents([.fraction(0.5)])
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.5)))
        .presentationDragIndicator(.visible)
    }

    private func handlePopupOutcome(for place: IdentifiablePlace, outcome: String, fileName: String?) {
        pendingAddress = place.address
        pendingSelectedContact = place.selectedContact
        isTappedAddressCustomer = place.list == "Customers"
        popupState = nil
        resetSelectedMapMarker()

        if outcome == "Follow Up Later" {
            pendingRecordingFileName = fileName
            stepperState = .init(
                ctx: .init(
                    address: place.address,
                    isCustomer: isTappedAddressCustomer,
                    prospect: nil
                )
            )
        } else {
            handleOutcome(outcome, recordingFileName: fileName)
        }
    }
    
    // For updating the markers
    private func updateMarkers() {
        controller.setMarkers(prospects: filteredProspectsForMap, customers: filteredCustomersForMap)
    }

    private func clearContactFilter() {
        MapScreenHapticsController.shared.lightTap()
        MapScreenSoundController.shared.playPropertyOpen()
        withAnimation(.easeInOut(duration: 0.2)) {
            contactSearchText = ""
        }
    }

    private func contactMatchesFilter<T: ContactProtocol>(_ contact: T) -> Bool {
        let query = activeContactFilter
        guard !query.isEmpty else { return true }

        return contact.fullName.localizedCaseInsensitiveContains(query) ||
            contact.address.localizedCaseInsensitiveContains(query) ||
            contact.contactPhone.localizedCaseInsensitiveContains(query) ||
            contact.contactEmail.localizedCaseInsensitiveContains(query) ||
            contact.demographicsSearchText.localizedCaseInsensitiveContains(query)
    }
    
    private func resolveProspectForSale(address: String) -> Prospect? {
        // 1) If user selected a specific contact, use it
        if let selected = pendingSelectedContact {
            switch selected {
            case .prospect(let p):
                return p
            case .customer:
                return nil
            }
        }

        // 2) Fallback: single-contact address
        return prospects.first { addressesMatch($0.address, address) }
    }
    
    // For converting to customer
    @ViewBuilder
    private func stepperOverlay(geo: GeometryProxy) -> some View {
        Group {
            if let s = stepperState {
                KnockStepperPopupView(
                    context: s.ctx,
                    objections: objections,
                    saveKnock: { outcome in
                        if s.ctx.isCustomer {
                            let customerController = CustomerKnockActionController(
                                modelContext: modelContext,
                                controller: controller
                            )

                            let customer = customerController.saveKnockOnly(
                                address: s.ctx.address,
                                status: outcome.rawValue,
                                customers: customers,
                                onUpdateMarkers: { updateMarkers() }
                            )

                            // UI continuity only
                            let p = Prospect(
                                fullName: customer.fullName,
                                address: customer.address,
                                count: customer.knockCount,
                                list: "Customers"
                            )
                            p.latitude = customer.latitude
                            p.longitude = customer.longitude
                            return p
                        } else {
                            return prospectKnockingController!.saveKnockOnly(
                                address: s.ctx.address,
                                status: outcome.rawValue,
                                prospects: prospects,
                                onUpdateMarkers: { updateMarkers() }
                            )
                        }
                    },
                    incrementObjection: { obj in
                        obj.timesHeard += 1

                        if recordingFeaturesActive,
                           let name = pendingRecordingFileName {
                            let rec = Recording(
                                fileName: name,
                                title: obj.text,
                                date: .now,
                                objection: obj,
                                rating: 3
                            )
                            modelContext.insert(rec)
                            pendingRecordingFileName = nil
                        }

                        try? modelContext.save()
                    },
                    saveFollowUp: { prospect, date in
                        saveFollowUp(for: s.ctx, prospect: prospect, date: date)
                    },
                    convertToCustomer: { prospect, done in
                        prospectToConvert = prospect
                        showConversionSheet = true
                        done()
                    },
                    addNote: { prospect, text in
                        prospect.notes.append(Note(content: text))
                        try? modelContext.save()
                    },
                    logTrip: { start, end, date in
                        guard !end.isEmpty else { return }
                        let trip = Trip(
                            startAddress: start,
                            endAddress: end,
                            miles: 0,
                            date: date
                        )
                        modelContext.insert(trip)
                        try? modelContext.save()
                    },
                    onClose: { completed in
                        let completedAddress = s.ctx.address
                        stepperState = nil
                        guard completed else { return }
                        showFollowUpScheduledConfirmation(for: completedAddress, in: geo)
                    }
                )
                .padding(.horizontal, 12)
                .frame(width: geo.size.width, height: geo.size.height * 0.75, alignment: .top)
                .position(
                    x: geo.size.width / 2,
                    y: geo.size.height * 0.58
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }
        }
    }
    
    /// Helper function to create the popup for Prospect or Customer
    private func showPopup(for place: IdentifiablePlace) {
        
        selectedPlaceID = place.id
        
        withAnimation(.easeInOut(duration: 0.35)) {
            controller.centerMapForPopup(coordinate: place.location)
        }
        
        presentPopup(for: place)
        
    }

    private func presentPopup(for place: IdentifiablePlace) {
        popupState = PopupState(place: place)
    }
    
    private func handleOutcome(_ status: String, recordingFileName: String?) {

        guard let addr = pendingAddress else { return }

        // =========================
        // CUSTOMER FLOW
        // =========================
        if isTappedAddressCustomer {

            switch status {

            case "Wasn't Home":
                let customerController = CustomerKnockActionController(
                    modelContext: modelContext,
                    controller: controller
                )

                customerController.handleKnockAndUpdateMarker(
                    address: addr,
                    status: status,
                    customers: customers,
                    onUpdateMarkers: { updateMarkers() }
                )

            case "Follow Up Later":
                pendingRecordingFileName = recordingFileName
                stepperState = .init(
                    ctx: .init(
                        address: addr,
                        isCustomer: true,
                        prospect: nil
                    )
                )
            
            case "Customer Lost":
                convertCustomerToProspect(address: addr)

            default:
                // Customers should never hit Converted To Sale
                assertionFailure("Invalid outcome '\(status)' for Customer")
            }

            try? modelContext.save()
            return
        }

        // =========================
        // PROSPECT FLOW
        // =========================
        switch status {

        case "Converted To Sale":
            if let prospect = resolveProspectForSale(address: addr) {

                // Log knock
                prospectKnockingController?.saveKnockOnly(
                    address: addr,
                    status: status,
                    prospects: prospects,
                    onUpdateMarkers: { updateMarkers() }
                )

                // Trigger sale sheet with CORRECT person
                prospectToConvert = prospect
                showConversionSheet = true
            }

        case "Follow Up Later":
            pendingRecordingFileName = recordingFileName
            stepperState = .init(
                ctx: .init(
                    address: addr,
                    isCustomer: false,
                    prospect: nil
                )
            )

        case "Wasn't Home":
            prospectKnockingController?.handleKnockAndPromptNote(
                address: addr,
                status: status,
                prospects: prospects,
                onUpdateMarkers: { updateMarkers() }
            )
            
        case "Unqualified":
            prospectKnockingController?.saveKnockOnly(
                address: addr,
                status: status,
                prospects: prospects,
                onUpdateMarkers: { updateMarkers() }
            )
        
        case "Requalified":
            if let prospect = prospects.first(where: {
                addressesMatch($0.address, addr)
            }) {

                // 1️⃣ Clear unqualified flag
                prospect.isUnqualified = false

                // 2️⃣ Clean up name (remove suffix)
                prospect.fullName = prospect.fullName
                    .replacingOccurrences(of: " - Unqualified", with: "")

                // 3️⃣ Log a knock for history
                prospectKnockingController?.saveKnockOnly(
                    address: addr,
                    status: "Requalified",
                    prospects: prospects,
                    onUpdateMarkers: { updateMarkers() }
                )
            }

        default:
            break
        }

        try? modelContext.save()
        pendingSelectedContact = nil
    }
    
    private func openDetails(for place: IdentifiablePlace) {
        // Close popup first (important for UX)
        closePopup()

        if let selectedContact = place.selectedContact {
            switch selectedContact {
            case .prospect(let prospect):
                selectedProspect = prospect
            case .customer(let customer):
                selectedCustomer = customer
            }
            return
        }

        if place.list == "Customers" ,
           let customer = customers.first(where: { $0.address == place.address }) {
            selectedCustomer = customer
            return
        }

        if let prospect = prospects.first(where: { $0.address == place.address }) {
            selectedProspect = prospect
        }
    }
    
    @MainActor
    private func closePopup() {
        popupState = nil
        selectedPlaceID = nil

        // Force MapKit to deselect the annotation
        if let mapView = MapDisplayView.cachedMapView {
            DispatchQueue.main.async {
                mapView.selectedAnnotations.forEach {
                    mapView.deselectAnnotation($0, animated: false)
                }
            }
        }
    }
    
    private func unitContactGroupsForBaseAddress(_ base: String) -> [UnitContactGroup] {

        let prospectUnits = filteredProspectsForMap
            .filter {
                parseAddress($0.address).base.lowercased() == base.lowercased()
            }
            .map { UnitContact.prospect($0) }

        let customerUnits = filteredCustomersForMap
            .filter {
                parseAddress($0.address).base.lowercased() == base.lowercased()
            }
            .map { UnitContact.customer($0) }

        let contacts = prospectUnits + customerUnits
        let grouped = Dictionary(grouping: contacts) { contact in
            parseAddress(contact.address).unit
        }

        return grouped
            .map { unit, contacts in
                UnitContactGroup(unit: unit, contacts: sortedContacts(contacts))
            }
            .sorted { lhs, rhs in
                unitSortKey(lhs.unit).localizedStandardCompare(unitSortKey(rhs.unit)) == .orderedAscending
            }
    }

    private func sortedContacts(_ contacts: [UnitContact]) -> [UnitContact] {
        contacts.sorted { lhs, rhs in
            if lhs.isCustomer != rhs.isCustomer {
                return lhs.isCustomer
            }

            return contactName(for: lhs).localizedStandardCompare(contactName(for: rhs)) == .orderedAscending
        }
    }

    private func unitSortKey(_ unit: String?) -> String {
        guard let unit else { return "0000" }
        return unit
    }

    private func contactName(for contact: UnitContact) -> String {
        switch contact {
        case .prospect(let prospect):
            return prospect.fullName
        case .customer(let customer):
            return customer.fullName
        }
    }
    
    private func saveFollowUp(
        for ctx: KnockContext,
        prospect: Prospect,
        date: Date
    ) {
        if ctx.isCustomer {
            guard let customer = customers.first(where: {
                addressesMatch($0.address, ctx.address)
            }) else { return }

            let appt = Appointment(
                title: "Follow-Up",
                location: customer.address,
                clientName: customer.fullName,
                date: date,
                type: "Follow-Up",
                notes: customer.notes.map { $0.content },
                customer: customer
            )

            customer.appointments.append(appt)
            modelContext.insert(appt)
        } else {
            let appt = Appointment(
                title: "Follow-Up",
                location: prospect.address,
                clientName: prospect.fullName,
                date: date,
                type: "Follow-Up",
                notes: prospect.notes.map { $0.content },
                prospect: prospect
            )
            modelContext.insert(appt)
        }

        try? modelContext.save()
    }
    
    /// This function handles adding new prospects to the map
    /// It will simply ask if the prospect selected should be added or not
    /// The assumption is that sales reps will want to pre-load their prospects the day before they knock it
    private func addProspectFromMapTap(address: String, coordinate: CLLocationCoordinate2D) {
        let newProspect = Prospect(
            fullName: "New Prospect",
            address: address,
            count: 0,
            list: "Prospects"
        )
        
        // Assign coordinates once
        newProspect.latitude = coordinate.latitude
        newProspect.longitude = coordinate.longitude

        modelContext.insert(newProspect)
        try? modelContext.save()
        
        // 🔍 Print for testing
        print("""
        📍 Prospect created
        Address: \(address)
        Latitude: \(coordinate.latitude)
        Longitude: \(coordinate.longitude)
        """)
        
        // Add marker WITHOUT geocoding
        controller.markers.append(
            IdentifiablePlace(
                address: address,
                location: coordinate,
                count: 0,
                list: "Prospects"
            )
        )

        NotificationCenter.default.post(
            name: .didAddPropertyMarker,
            object: nil,
            userInfo: ["location": CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)]
        )
    }
    
    @MainActor
    private func convertCustomerToProspect(address: String) {
        
        guard let customer = customers.first(where: {
            addressesMatch($0.address, address)
        }) else { return }

        // 1️⃣ Create Prospect from Customer
        let prospect = Prospect(
            fullName: customer.fullName,
            address: customer.address,
            count: customer.knockCount,
            list: "Prospects"
        )

        // 2️⃣ Carry everything over
        prospect.contactPhone = customer.contactPhone
        prospect.contactEmail = customer.contactEmail
        prospect.notes = customer.notes
        prospect.appointments = customer.appointments
        prospect.knockHistory = customer.knockHistory
        
        // ✅ 2.1 Transfer emails BACK to prospect
        transferEmailsToProspect(from: customer, to: prospect)
        
        // 2.2️⃣ Transfer phone calls back to prospect
        prospect.phoneCalls = customer.phoneCalls
        
        // ✅ Update ownership metadata
        for call in prospect.phoneCalls {
            call.recipientUUID = prospect.uuid
            call.recipientType = .prospect
        }
        
        // 2.5 LOG THE STATE TRANSITION
        prospect.knockHistory.append(
            Knock(
                date: .now,
                status: "Customer Lost",
                latitude: prospect.latitude ?? customer.latitude ?? 0,
                longitude: prospect.longitude ?? customer.longitude ?? 0
            )
        )

        // 3️⃣ Preserve spatial identity
        prospect.latitude = customer.latitude
        prospect.longitude = customer.longitude

        // 4️⃣ Persist new Prospect
        modelContext.insert(prospect)

        // 5️⃣ Delete Customer (single source of truth)
        modelContext.delete(customer)

        // 6️⃣ Save + refresh UI
        try? modelContext.save()
        updateMarkers()

        // Optional UX
        selectedList = "Prospects"
    }
    
    @MainActor
    private func handleMapCenterChange(newAddress: String?) {
        
        guard let query = newAddress else { return }
        
        Task { @MainActor [controller] in
            
            if let coord = await controller.geocodeAddress(query) {
                withAnimation {
                    controller.region = MKCoordinateRegion(
                        center: coord,
                        latitudinalMeters: 1609.34,
                        longitudinalMeters: 1609.34
                    )
                }
            }
            addressToCenter = nil
        }
    }

    private func displayAddress(for item: MKMapItem, fallback: String) -> String {
        item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true)
        ?? item.address?.fullAddress
        ?? item.name
        ?? fallback
    }

    private func handleCompletionTap(_ result: MKLocalSearchCompletion) {
        
        let req = MKLocalSearch.Request(completion: result)
        
        MKLocalSearch(request: req).start { resp, _ in
            guard let item = resp?.mapItems.first else { return }
            let addr = displayAddress(for: item, fallback: result.title)
            let coordinate = item.location.coordinate

            DispatchQueue.main.async {
                clearMapSearchState()
                pendingAddress = addr

                // Determine zoom: ~1 mile (1609 meters) or adjust based on your UX preference
                let region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )

                // Animate the region change
                withAnimation(.easeInOut(duration: 0.4)) {
                    controller.region = region
                }
                
                // 1️⃣ Check if it's a Prospect
                if let existingProspect = prospects.first(where: {
                    addressesMatch($0.address, addr)
                }) {
                    let place = IdentifiablePlace(
                        address: existingProspect.address,
                        location: CLLocationCoordinate2D(
                            latitude: existingProspect.latitude ?? controller.region.center.latitude,
                            longitude: existingProspect.longitude ?? controller.region.center.longitude
                        ),
                        count: existingProspect.knockHistory.count,
                        list: existingProspect.list
                    )
                    showPopup(for: place)
                }
                // 2️⃣ Check if it's a Customer
                else if let existingCustomer = customers.first(where: {
                    addressesMatch($0.address, addr)
                }) {
                    let place = IdentifiablePlace(
                        address: existingCustomer.address,
                        location: CLLocationCoordinate2D(
                            latitude: existingCustomer.latitude ?? controller.region.center.latitude,
                            longitude: existingCustomer.longitude ?? controller.region.center.longitude
                        ),
                        count: existingCustomer.knockHistory.count,
                        list: "Customers"
                    )
                    showPopup(for: place)
                }
                // 3️⃣ Otherwise, add as new property
                else {
                    presentPendingAddProperty(address: addr, coordinate: coordinate)
                }
            }
        }
    }
    
    private func addressesMatch(_ a: String, _ b: String) -> Bool {
        let normalize: (String) -> String = {
            $0.lowercased()
              .replacingOccurrences(of: ",", with: "")
              .replacingOccurrences(of: "  ", with: " ")
              .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let na = normalize(a)
        let nb = normalize(b)

        return na.contains(nb) || nb.contains(na)
    }

    private func showFollowUpScheduledConfirmation(for address: String, in geo: GeometryProxy) {
        let position = followUpConfirmationPosition(for: address, in: geo)

        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
            followUpScheduledConfirmation = FollowUpScheduledConfirmation(
                address: address,
                position: position
            )
        }
    }

    private func followUpConfirmationPosition(for address: String, in geo: GeometryProxy) -> CGPoint {
        if let mapView = MapDisplayView.cachedMapView,
           let marker = mapMarkers.first(where: { addressesMatch($0.address, address) }) {
            let raw = mapView.convert(marker.location, toPointTo: mapView)
            return clampedMapConfirmationPosition(
                CGPoint(x: raw.x, y: raw.y - 72),
                in: geo
            )
        }

        if let popupScreenPosition {
            return clampedMapConfirmationPosition(
                CGPoint(x: popupScreenPosition.x, y: popupScreenPosition.y - 36),
                in: geo
            )
        }

        return CGPoint(
            x: geo.size.width / 2,
            y: min(max(geo.size.height * 0.32, 120), geo.size.height - 260)
        )
    }

    private func clampedMapConfirmationPosition(_ point: CGPoint, in geo: GeometryProxy) -> CGPoint {
        let halfWidth: CGFloat = 118
        let halfHeight: CGFloat = 72
        let minX = halfWidth + 12
        let maxX = max(minX, geo.size.width - halfWidth - 12)
        let minY = halfHeight + 24
        let maxY = max(minY, geo.size.height - halfHeight - 220)
        let x = min(max(point.x, minX), maxX)
        let y = min(max(point.y, minY), maxY)
        return CGPoint(x: x, y: y)
    }

    private func clearMapSearchState() {
        searchText = ""
        searchVM.clear()
        isSearchFocused = false
        isSearchExpanded = false
    }

    private func submitSearch() {
        let query = searchText
        clearMapSearchState()

        Task { @MainActor in
            guard let item = await SearchBarController.resolveFreeformSearch(query: query) else {
                return
            }

            let address = displayAddress(for: item, fallback: query)
            let coordinate = item.location.coordinate

            clearMapSearchState()

            pendingAddress = address

            // 📍 Move map
            withAnimation(.easeInOut(duration: 0.4)) {
                controller.region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
            }

            // 🔍 Existing Prospect?
            if let prospect = prospects.first(where: {
                addressesMatch($0.address, address)
            }) {
                showPopup(
                    for: IdentifiablePlace(
                        address: prospect.address,
                        location: CLLocationCoordinate2D(
                            latitude: prospect.latitude ?? coordinate.latitude,
                            longitude: prospect.longitude ?? coordinate.longitude
                        ),
                        count: prospect.knockHistory.count,
                        list: prospect.list
                    )
                )
                return
            }

            // 🔍 Existing Customer?
            if let customer = customers.first(where: {
                addressesMatch($0.address, address)
            }) {
                showPopup(
                    for: IdentifiablePlace(
                        address: customer.address,
                        location: CLLocationCoordinate2D(
                            latitude: customer.latitude ?? coordinate.latitude,
                            longitude: customer.longitude ?? coordinate.longitude
                        ),
                        count: customer.knockHistory.count,
                        list: "Customers"
                    )
                )
                return
            }

            // ➕ New property
            presentPendingAddProperty(address: address, coordinate: coordinate)
        }
    }
}

private struct FollowUpScheduledConfirmation: Identifiable {
    let id = UUID()
    let address: String
    let position: CGPoint
}

private struct FollowUpScheduledMapConfirmationView: View {
    let address: String

    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.teal.opacity(isPulsing ? 0 : 0.38), lineWidth: 2)
                    .frame(width: isPulsing ? 108 : 40, height: isPulsing ? 108 : 40)

                Circle()
                    .fill(Color.teal.opacity(0.16))
                    .frame(width: 48, height: 48)

                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.teal)
            }
            .frame(width: 110, height: 72)

            VStack(spacing: 2) {
                Text("Follow-up scheduled")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(shortAddress(address))
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 236)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.teal.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 16, x: 0, y: 8)
        .onAppear {
            withAnimation(.easeOut(duration: 1.05).repeatCount(2, autoreverses: false)) {
                isPulsing = true
            }
        }
    }

    private func shortAddress(_ full: String) -> String {
        let parts = full.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        if parts.count >= 2 { return parts[0] + ", " + parts[1] }
        return full
    }
}
