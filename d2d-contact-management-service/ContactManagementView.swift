//
//  ProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import SwiftData
import ContactsUI

struct ContactManagementView: View {
    private struct ExportFile: Identifiable {
        let id = UUID()
        let url: URL
    }

    private enum ActiveSheet: Identifiable {
        case export(ExportFile)
        case emailGate
        case addProspect

        var id: String {
            switch self {
            case .export(let file):
                return "export-\(file.id)"
            case .emailGate:
                return "emailGate"
            case .addProspect:
                return "addProspect"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Binding var selectedList: String
    @Binding var searchText: String
    var onSave: () -> Void

    // Shared state
    @StateObject private var controller = ContactManagerController()

    // Menu + overlays
    @State private var showingImportFromContacts = false
    @State private var showImportSuccess = false

    @Query private var prospects: [Prospect]
    @Query private var customers: [Customer]
    
    @State private var showingAddCustomer = false
    
    @State private var selectedProspect: Prospect?
    @State private var selectedCustomer: Customer?
    
    @FocusState private var isSearchFocused: Bool
    
    @State private var isDeletingContacts = false
    @State private var selectedProspects: Set<Prospect> = []
    @State private var selectedCustomers: Set<Customer> = []
    @State private var showDeleteContactsConfirm = false
    
    private var selectedDeleteCount: Int {
        selectedList == "Prospects"
            ? selectedProspects.count
            : selectedCustomers.count
    }
    
    @State private var activeSheet: ActiveSheet?
    @StateObject private var emailGate = EmailGateManager.shared
    
    @State private var showDuplicateToast = false
    @State private var duplicateNames: [String] = []
    
    var body: some View {
        
        NavigationView {
            ZStack {
                
                managementContent

                // Toolbar
                ContactsToolbarView(
                    onAddTapped: {
                        if selectedList == "Prospects" {
                            withAnimation(.spring()) {
                                showingImportFromContacts = true
                            }
                        } else {
                            showingAddCustomer = true
                        }
                    },
                    isDeleting: $isDeletingContacts,
                    selectedCount: selectedDeleteCount,
                    onDeleteConfirmed: {
                        showDeleteContactsConfirm = true
                    }
                )
                
            }
            .navigationTitle("")
            .overlay(
                GeometryReader { geo in
                    ExportCSVButton(isUnlocked: emailGate.isUnlocked) {
                        
                        if emailGate.isUnlocked {
                            
                            ContactScreenHapticsController.shared.successConfirmationTap()
                            ContactScreenSoundController.shared.playSound1()
                            
                            performExport()
                            
                        } else {
                            
                            ContactScreenHapticsController.shared.successConfirmationTap()
                            ContactScreenSoundController.shared.playSound1()
                            
                            activeSheet = .emailGate
                            
                        }
                    }
                    .position(
                        x: geo.size.width - 45, // 20 trailing + 25 half width
                        y: geo.size.height - 55 // 30 bottom + 25 half height
                    )
                    .zIndex(999)
                }
            )
            .overlay(
                ImportOverlayView(
                    showingImportFromContacts: $showingImportFromContacts,
                    showImportSuccess: $showImportSuccess,
                    selectedList: $selectedList,
                    searchText: $searchText,
                    prospects: prospects,
                    customers: customers,
                    modelContext: modelContext,
                    onSave: onSave,
                    onOpenDuplicateProspect: { prospect in
                        selectedProspect = prospect
                    },
                    onOpenDuplicateCustomer: { customer in
                        selectedCustomer = customer
                    },
                    onAddManually: {
                        activeSheet = .addProspect
                    },
                    showDuplicateToast: $showDuplicateToast,
                    duplicateNames: $duplicateNames
                )
            )
            .overlay(
                Group {
                    if showImportSuccess {
                        ToastMessageView(message: "Contacts imported successfully!")
                    } else if showDuplicateToast {
                        let message = duplicateNames.joined(separator: ", ") + " already exist."
                        ToastMessageView(message: message)
                    }
                }
            )
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .export(let file):
                    ShareSheet(activityItems: [file.url])
                case .emailGate:
                    ExportEmailGateView {
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            performExport()
                        }
                    }
                    .presentationDetents([.fraction(0.5)])
                    .presentationDragIndicator(.visible)
                case .addProspect:
                    ProspectCreateStepperView { newProspect in
                        modelContext.insert(newProspect)
                        try? modelContext.save()

                        searchText = ""
                        activeSheet = nil
                        onSave()
                    } onCancel: {
                        activeSheet = nil
                    }
                    .presentationDetents([.fraction(0.5)]) // 50% of screen height
                    .presentationDragIndicator(.visible)    // optional: show the drag handle
                }
            }
            .alert("Delete selected contacts?",
                   isPresented: $showDeleteContactsConfirm) {

                Button("Delete", role: .destructive) {
                    
                    ContactScreenHapticsController.shared.mediumTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                    deleteSelectedContacts()
                    
                }

                Button("Cancel", role: .cancel) {
                    
                    ContactScreenHapticsController.shared.mediumTap()
                    ContactScreenSoundController.shared.playSound1()
                    
                }
            }
            .onChange(of: selectedList) { _, newValue in
                if newValue == "Prospects" {
                    Task {
                        await controller.fetchNextSuggestedNeighbor(
                            from: customers,
                            existingProspects: prospects
                        )
                    }
                }
            }
        }
    }
    
    private func performExport() {
        do {
            let url: URL
            if selectedList == "Prospects" {
                url = try CSVExportService.exportProspects(prospects)
            } else {
                url = try CSVExportService.exportCustomers(customers)
            }
            activeSheet = .export(ExportFile(url: url))
        } catch {
            print("❌ Export failed:", error)
        }
    }
    
    @ViewBuilder
    private var managementContent: some View {
        if selectedList == "Prospects" {
            ProspectManagementView(
                searchText: $searchText,
                suggestedProspect: $controller.suggestedProspect,
                selectedList: $selectedList,
                onSave: onSave,
                selectedProspect: $selectedProspect,
                isSearchFocused: $isSearchFocused,
                isDeleting: $isDeletingContacts,
                selectedProspects: $selectedProspects
            )
        } else {
            CustomerManagementView(
                searchText: $searchText,
                selectedList: $selectedList,
                onSave: onSave,
                showingAddCustomer: $showingAddCustomer,
                selectedCustomer: $selectedCustomer,
                isSearchFocused: $isSearchFocused,
                isDeleting: $isDeletingContacts,
                selectedCustomers: $selectedCustomers
            )
        }
    }
    
    private func deleteSelectedContacts() {
        
        withAnimation {
            
            ContactScreenHapticsController.shared.successConfirmationTap()
            ContactScreenSoundController.shared.playSound1()

            if selectedList == "Prospects" {
                for p in selectedProspects {
                    p.appointments.forEach { modelContext.delete($0) }
                    modelContext.delete(p)
                }
                selectedProspects.removeAll()
            } else {
                for c in selectedCustomers {
                    c.appointments.forEach { modelContext.delete($0) }
                    modelContext.delete(c)
                }
                selectedCustomers.removeAll()
            }

            try? modelContext.save()
            isDeletingContacts = false
        }
    }
    
}
