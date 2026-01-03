//
//  ImportOverlayView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/12/25.
//


import SwiftUI
import SwiftData
import ContactsUI
import CoreLocation

struct ImportOverlayView: View {
    @Binding var showingImportFromContacts: Bool
    @Binding var showImportSuccess: Bool
    @Binding var selectedList: String
    @Binding var searchText: String

    let prospects: [Prospect]
    let customers: [Customer]
    let modelContext: ModelContext
    let onSave: () -> Void
    
    let onAddManually: () -> Void

    @State private var showContactsPicker = false
    
    @State private var showBusinessCardScanner = false
    @State private var scannedProspectDraft: ProspectDraft?
    
    @StateObject private var importManager: ContactImportManager
    
    @Binding var showDuplicateToast: Bool
    @Binding var duplicateNames: [String]
    
    // ✅ Custom initializer to properly inject StateObject
    init(
        showingImportFromContacts: Binding<Bool>,
        showImportSuccess: Binding<Bool>,
        selectedList: Binding<String>,
        searchText: Binding<String>,
        prospects: [Prospect],
        customers: [Customer],
        modelContext: ModelContext,
        onSave: @escaping () -> Void,
        onAddManually: @escaping () -> Void,
        showDuplicateToast: Binding<Bool>,
        duplicateNames: Binding<[String]>
    ) {
        self._showingImportFromContacts = showingImportFromContacts
        self._showImportSuccess = showImportSuccess
        self._selectedList = selectedList
        self._searchText = searchText
        self.prospects = prospects
        self.customers = customers
        self.modelContext = modelContext
        self.onSave = onSave
        self.onAddManually = onAddManually

        // ✅ Initialize StateObject here
        _importManager = StateObject(wrappedValue: ContactImportManager(
            modelContext: modelContext,
            prospects: prospects,
            customers: customers,
            onSave: onSave
        ))
        
        self._showDuplicateToast = showDuplicateToast
        self._duplicateNames = duplicateNames
    }

    var body: some View {
        
        if showingImportFromContacts {
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                VStack(spacing: 6) {
                    Text("Add Prospect")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Choose how you’d like to add a new prospect")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    
                    actionButton(
                        title: "Import from Contacts",
                        subtitle: "Select one or more contacts",
                        systemImage: "person.crop.circle.badge.plus"
                    ) {
                        showContactsPicker = true
                    }

                    actionButton(
                        title: "Add Manually",
                        subtitle: "Enter details yourself",
                        systemImage: "square.and.pencil"
                    ) {
                        showingImportFromContacts = false
                        
                        onAddManually()
                    }
                    
                    actionButton(
                        title: "Scan Business Card",
                        subtitle: "Use your camera to add a prospect",
                        systemImage: "camera.viewfinder"
                    ) {
                        showBusinessCardScanner = true
                    }
                }
                
                Button("Cancel") {
                    showingImportFromContacts = false
                }
                .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .frame(maxWidth: 340, maxHeight: 400)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 8)
            .position(
                x: UIScreen.main.bounds.midX,
                y: UIScreen.main.bounds.midY
            )
            .transition(.scale.combined(with: .opacity))
            .zIndex(2000)
            .sheet(isPresented: $showContactsPicker) {
                ContactsImportView(
                    onComplete: handleContactsImported,
                    onCancel: { showContactsPicker = false }
                )
            }
            .sheet(item: $scannedProspectDraft) { draft in
                BusinessCardConfirmView(
                    draft: draft,
                    onConfirm: { confirmedDraft in
                        saveProspect(confirmedDraft)
                        scannedProspectDraft = nil
                        showingImportFromContacts = false
                    }
                )
            }
            .sheet(isPresented: $showBusinessCardScanner) {
                BusinessCardScannerView(
                    onScanned: { draft in
                        scannedProspectDraft = draft
                        showBusinessCardScanner = false
                    },
                    onCancel: {
                        showBusinessCardScanner = false
                    }
                )
            }
        }
    }
    
    private func saveProspect(_ draft: ProspectDraft) {
        let prospect = Prospect(
            fullName: draft.fullName,
            address: draft.address,
            list: "Prospects"
        )

        prospect.contactPhone = draft.phone
        prospect.contactEmail = draft.email

        CLGeocoder().geocodeAddressString(draft.address) { placemarks, _ in
            if let coord = placemarks?.first?.location?.coordinate {
                prospect.latitude = coord.latitude
                prospect.longitude = coord.longitude
            }

            modelContext.insert(prospect)
            try? modelContext.save()
            onSave()
        }
    }

    // MARK: - Import Logic

    private func handleContactsImported(_ contacts: [CNContact]) {
        showContactsPicker = false
        showingImportFromContacts = false

        let (didAdd, duplicates) = importManager.importContacts(contacts)

        selectedList = "Prospects"
        searchText = ""

        if didAdd {
            showImportSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showImportSuccess = false
            }
        }

        if !duplicates.isEmpty {
            duplicateNames = duplicates
            showDuplicateToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showDuplicateToast = false
            }
        }
    }

    // MARK: - Button

    private func actionButton(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
        }
        .buttonStyle(.plain)
    }
}
