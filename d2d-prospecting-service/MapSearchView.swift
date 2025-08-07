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
import Combine
import Contacts

struct MapSearchView: View {
    @Binding var searchText: String
    @Binding var region: MKCoordinateRegion
    @Binding var selectedList: String
    @Binding var addressToCenter: String?

    @Query private var prospects: [Prospect]
    @Query private var customers: [Customer]

    @StateObject private var controller: MapController
    @State private var pendingAddress: String?
    @State private var showOutcomePrompt = false
    @State private var showNoteInput = false
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

    @StateObject private var searchVM = SearchCompleterViewModel()

    @FocusState private var isSearchFocused: Bool

    @State private var isTappedAddressCustomer = false

    struct PopupState: Identifiable, Equatable {
        let id = UUID()
        let place: IdentifiablePlace

        static func == (lhs: PopupState, rhs: PopupState) -> Bool {
            lhs.id == rhs.id
        }
    }

    @State private var popupState: PopupState?

    @State private var popupScreenPosition: CGPoint? = nil
    
    @State private var isSearchExpanded = false
    @Namespace private var animationNamespace

    @Environment(\.modelContext) private var modelContext
    
    @State private var pendingRecordingFileName: String?
    
    @AppStorage("recordingModeEnabled") private var recordingModeEnabled: Bool = true
    
    @State private var knockController: KnockActionController? = nil

    private var hasSignedUp: Bool {
        prospects
            .flatMap { $0.knockHistory }
            .contains { $0.status == "Converted To Sale" }
    }

    private var totalKnocks: Int {
        prospects.flatMap { $0.knockHistory }.count
    }

    private var averageKnocksPerCustomer: Int {
        let customerKnocks = prospects
            .filter { $0.list == "Customers" }
            .map { $0.knockHistory.count }
        guard !customerKnocks.isEmpty else { return 0 }
        return Int(Double(customerKnocks.reduce(0, +)) / Double(customerKnocks.count))
    }

    init(searchText: Binding<String>,
         region: Binding<MKCoordinateRegion>,
         selectedList: Binding<String>,
         addressToCenter: Binding<String?>) {
        _searchText = searchText
        _region = region
        _selectedList = selectedList
        _addressToCenter = addressToCenter
        _controller = StateObject(wrappedValue: MapController(region: region.wrappedValue))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                
                MapDisplayView(
                    region: $controller.region,
                    markers: controller.markers,
                    onMarkerTapped: { place in
                        let state = PopupState(place: place)
                        popupState = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            popupState = state
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
                    },
                    onMapTapped: { coordinate in
                        tapManager.handleTap(at: coordinate)
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.6) {
                            let tapped = tapManager.tappedAddress
                            if !tapped.isEmpty {
                                pendingAddress = tapped
                                isTappedAddressCustomer = customers.contains {
                                    $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                                    tapped.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                showOutcomePrompt = true
                            }
                        }
                    },
                    onRegionChange: { newRegion in
                        controller.region = newRegion
                        // close popup on any pan/zoom
                        if popupState != nil {
                            popupState = nil
                        }
                    }
                )
                .frame(maxHeight: .infinity)
                .edgesIgnoringSafeArea(.horizontal)

                ScorecardBar(totalKnocks: totalKnocks,
                             avgKnocksPerSale: averageKnocksPerCustomer,
                             hasSignedUp: hasSignedUp)

                prospectPopup
                
                FloatingSearchAndMicButtons(
                    searchText: $searchText,
                    isExpanded: $isSearchExpanded,
                    isFocused: $isSearchFocused,
                    viewModel: searchVM,
                    animationNamespace: animationNamespace,
                    onSubmit: { submitSearch() },
                    onSelectResult: { handleCompletionTap($0) }
                )
                
            }
        }
        .onChange(of: searchText) { searchVM.updateQuery($0) }
        .onAppear {
            updateMarkers()
            knockController = KnockActionController(modelContext: modelContext, controller: controller)
        }
        .onChange(of: prospects) { _ in updateMarkers() }
        .onChange(of: selectedList) { _ in updateMarkers() }
        .onChange(of: addressToCenter) { handleMapCenterChange(newAddress: $0) }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to:nil,from:nil,for:nil)
        }
        .alert("Knock Outcome",isPresented:$showOutcomePrompt) {
            if !isTappedAddressCustomer {
                Button("Converted To Sale"){ handleKnockAndConvertToCustomer(status:"Converted To Sale") }
            }
            
            Button("Wasn't Home"){
                if let addr = pendingAddress {
                    knockController?.handleKnockAndPromptNote(
                        address: addr,
                        status: "Wasn't Home",
                        prospects: prospects,
                        onUpdateMarkers: {
                            updateMarkers()
                        },
                        onShowNoteInput: { prospect in
                            prospectToNote = prospect
                            showNoteInput = true
                        }
                    )
                }
            }
            
            Button("Follow-Up Later"){
                
                if let addr = pendingAddress {
                    knockController?.handleKnockAndPromptObjection(
                        address: addr,
                        status: "Follow Up Later",
                        prospects: prospects,
                        objections: objections,
                        onUpdateMarkers: {
                            updateMarkers()
                        },
                        onShowObjectionPicker: { filtered, prospect in
                            objectionOptions = filtered
                            prospectToNote = prospect
                            followUpAddress = prospect.address
                            followUpProspectName = prospect.fullName
                            showObjectionPicker = true
                        },
                        onShowAddObjection: { prospect in
                            selectedObjection = nil
                            prospectToNote = prospect
                            followUpAddress = prospect.address
                            followUpProspectName = prospect.fullName
                            showingAddObjection = true
                        }
                    )
                }
                
            }
            
            Button("Cancel",role:.cancel){}
        } message: { Text("Did someone answer at \(pendingAddress ?? "this address")?") }
            .sheet(isPresented:$showNoteInput){
                if let prospect=prospectToNote {
                    LogNoteView(
                        prospect:prospect,
                        objection:selectedObjection,
                        pendingAddress:pendingAddress) {
                            followUpAddress=prospect.address;
                            followUpProspectName=prospect.fullName;
                            selectedObjection=nil;
                            // showFollowUpPrompt=true
                            showTripPrompt = true
                        }
                }
            }
        .sheet(isPresented:$showObjectionPicker){
            NavigationView{
                List(objectionOptions){
                    obj in
                    Button(obj.text) {
                        selectedObjection = obj
                        obj.timesHeard += 1
                        try? modelContext.save()
                        showObjectionPicker = false

                        // ✅ Insert recording now that objection is selected
                        if let name = pendingRecordingFileName {
                            let newRecording = Recording(fileName: name, date: .now, objection: obj, rating: 3)
                            modelContext.insert(newRecording)
                            try? modelContext.save()
                            pendingRecordingFileName = nil
                        }

                        showFollowUpSheet = true
                    }
                    
        }.navigationTitle("Why not interested?")
          .toolbar{ ToolbarItem(placement:.cancellationAction){ Button("Cancel"){ showObjectionPicker=false } } } } }
        
        .sheet(isPresented: $showingAddObjection, onDismiss: {
            if let prospect = prospectToNote {
                showFollowUpSheet = true
            }
        })
        {
            AddObjectionView()
        }
        
        .alert("Schedule Follow-Up?",isPresented:$showFollowUpPrompt){ Button("Yes"){ showFollowUpSheet=true }
                                                                  Button("No",role:.cancel){ showTripPrompt=true } } message:
              { Text("Schedule follow-up for \(followUpProspectName)?") }
            .sheet(isPresented:$showFollowUpSheet,onDismiss:{
                DispatchQueue.main.asyncAfter(deadline:.now()+0.3){
                    // showTripPrompt=true
                    showNoteInput = true
                }
            }) {
                if let prospect=prospectToNote {
                    FollowUpScheduleView(prospect:prospect)
                }
            }
        .alert("Log a trip?",isPresented:$showTripPrompt){ Button("Yes"){ showTripPopup=true }
                                                      Button("No",role:.cancel){} }
        .sheet(isPresented:$showTripPopup){ if let addr=pendingAddress { LogTripPopupView(endAddress:addr) } }
        .sheet(isPresented:$showConversionSheet){ if let prospect=prospectToConvert { SignUpPopupView(prospect:prospect,isPresented:$showConversionSheet) } }
    }
    
    
    private var prospectPopup: some View {
        Group {
            if let popup = popupState, let pos = popupScreenPosition {
                ProspectPopupView(
                    place: popup.place,
                    isCustomer: popup.place.list == "Customers",
                    onClose: { popupState = nil },
                    onOutcomeSelected: { outcome, fileName in
                        pendingAddress = popup.place.address
                        isTappedAddressCustomer = popup.place.list == "Customers"
                        popupState = nil
                        handleOutcome(outcome, recordingFileName: fileName)
                    },
                    recordingModeEnabled: recordingModeEnabled
                )
                .frame(width: 240)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .position(pos)
                .zIndex(999)
                .id(popup.id) // <- force remount every time
            }
        }
    }
    
    private func handleOutcome(_ status: String, recordingFileName: String?) {
        if status == "Converted To Sale" {
            let objection = Objection(text: "Converted To Sale", response: "Handled successfully", timesHeard: 0)
            modelContext.insert(objection)
            if let name = recordingFileName {
                let newRecording = Recording(fileName: name, date: .now, objection: objection, rating: 5)
                modelContext.insert(newRecording)
            }
            handleKnockAndConvertToCustomer(status: status)

        } else if status == "Follow Up Later" {
            
            // Defer recording until objection is picked
            pendingRecordingFileName = recordingFileName
            
            if let addr = pendingAddress {
                knockController?.handleKnockAndPromptObjection(
                    address: addr,
                    status: "Follow Up Later",
                    prospects: prospects,
                    objections: objections,
                    onUpdateMarkers: {
                        updateMarkers()
                    },
                    onShowObjectionPicker: { filtered, prospect in
                        objectionOptions = filtered
                        prospectToNote = prospect
                        followUpAddress = prospect.address
                        followUpProspectName = prospect.fullName
                        showObjectionPicker = true
                    },
                    onShowAddObjection: { prospect in
                        selectedObjection = nil
                        prospectToNote = prospect
                        followUpAddress = prospect.address
                        followUpProspectName = prospect.fullName
                        showingAddObjection = true
                    }
                )
            }

        } else if status == "Wasn't Home" {
            if let addr = pendingAddress {
                knockController?.handleKnockAndPromptNote(
                    address: addr,
                    status: "Wasn't Home",
                    prospects: prospects,
                    onUpdateMarkers: {
                        updateMarkers()
                    },
                    onShowNoteInput: { prospect in
                        prospectToNote = prospect
                        showNoteInput = true
                    }
                )
            }
        }

        try? modelContext.save()
    }
    
    // This is for the prompts - might be redundant
    private func handleImmediateOutcome(_ status: String) {
        if status == "Converted To Sale" {
            
            handleKnockAndConvertToCustomer(status: status)
            
        } else if status == "Wasn't Home" {
            
            if let addr = pendingAddress {
                knockController?.handleKnockAndPromptNote(
                    address: addr,
                    status: "Wasn't Home",
                    prospects: prospects,
                    onUpdateMarkers: {
                        updateMarkers()
                    },
                    onShowNoteInput: { prospect in
                        prospectToNote = prospect
                        showNoteInput = true
                    }
                )
            }
            
        } else if status == "Follow Up Later" {
            
            if let addr = pendingAddress {
                knockController?.handleKnockAndPromptObjection(
                    address: addr,
                    status: "Follow Up Later",
                    prospects: prospects,
                    objections: objections,
                    onUpdateMarkers: {
                        updateMarkers()
                    },
                    onShowObjectionPicker: { filtered, prospect in
                        objectionOptions = filtered
                        prospectToNote = prospect
                        followUpAddress = prospect.address
                        followUpProspectName = prospect.fullName
                        showObjectionPicker = true
                    },
                    onShowAddObjection: { prospect in
                        selectedObjection = nil
                        prospectToNote = prospect
                        followUpAddress = prospect.address
                        followUpProspectName = prospect.fullName
                        showingAddObjection = true
                    }
                )
            }
            
        }
    }

    private func handleMapCenterChange(newAddress: String?) {
        guard let query = newAddress else { return }
        Task {
            if let coord = await controller.geocodeAddress(query) {
                withAnimation {
                    controller.region = MKCoordinateRegion(center: coord, latitudinalMeters:1609.34, longitudinalMeters:1609.34)
                }
            }
            addressToCenter = nil
        }
    }

    private func handleCompletionTap(_ result: MKLocalSearchCompletion) {
        let req = MKLocalSearch.Request(completion: result)
        MKLocalSearch(request:req).start{ resp,err in
            guard let item=resp?.mapItems.first else { return }
            let addr=item.placemark.title ?? "\(item.placemark.name ?? ""), \(item.placemark.locality ?? "")"
            DispatchQueue.main.async {
                
                // Keep the text after selecting an autofill address until hit done
                searchText=addr;
                
                pendingAddress=addr;
                controller.region=MKCoordinateRegion(center:item.placemark.coordinate,latitudinalMeters:1609.34,longitudinalMeters:1609.34);
                searchVM.results=[];
                isSearchFocused=false
            }
        }
    }

    private func submitSearch() {
        SearchHandler.submitManualSearch(
            searchText: searchText,
            pendingAddress: &pendingAddress,
            showOutcomePrompt: &showOutcomePrompt,
            clearSearchText: {
                searchText = ""
            }
        )
    }

    private func updateMarkers() {
        controller.setMarkers(prospects: prospects, customers: customers)
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
    
    private func handleKnockAndConvertToCustomer(status: String) {
        guard let addr = pendingAddress else { return }
        let prospect = saveKnock(address: addr, status: status)

        // Update the marker immediately to reflect "Customer" status
        if let index = controller.markers.firstIndex(where: {
            $0.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
            addr.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }) {
            controller.markers[index] = IdentifiablePlace(
                address: addr,
                location: controller.markers[index].location,
                count: controller.markers[index].count,
                list: "Customers"
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            updateMarkers()
        }

        prospectToConvert = prospect
        showConversionSheet = true
    }
}
