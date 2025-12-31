//
//  ProspectsSectionView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/25/25.
//

import SwiftUI
import SwiftData

struct ProspectsSectionView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allProspects: [Prospect]

    @Binding var selectedList: String
    @Binding var selectedProspect: Prospect?
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var prospectToDelete: Prospect?

    // From parent
    let containerHeight: CGFloat
    
    @Binding var searchText: String
    
    @Binding var isSearchExpanded: Bool
    @FocusState<Bool>.Binding var isSearchFocused: Bool

    private let rowHeight: CGFloat = 88

    private var filtered: [Prospect] {
        let base = allProspects
            .filter { $0.list == selectedList }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !q.isEmpty else {
            return base.sorted { $0.orderIndex < $1.orderIndex }
        }

        // Match name, address, phone, email (case-insensitive)
        let matches: (Prospect) -> Bool = { p in
            p.fullName.localizedCaseInsensitiveContains(q) ||
            p.address.localizedCaseInsensitiveContains(q) ||
            p.contactPhone.localizedCaseInsensitiveContains(q) ||
            p.contactEmail.localizedCaseInsensitiveContains(q)
        }

        return base.filter(matches)
            .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }
    
    @State private var draggingProspectID: PersistentIdentifier?

    var body: some View {
        let tableAreaHeight = max(containerHeight, rowHeight * 2)

        ZStack(alignment: .top) {
            Color(.systemGray6) // <- section background matches container
                .edgesIgnoringSafeArea(.all)
            
            if !filtered.isEmpty {
                List {
                    ForEach(filtered) { p in
                        ProspectRowView(prospect: p)
                            .scaleEffect(draggingProspectID == p.persistentModelID ? 1.03 : 1.0)
                            .shadow(
                                color: draggingProspectID == p.persistentModelID
                                    ? Color.black.opacity(0.18)
                                    : Color.black.opacity(0.05),
                                radius: draggingProspectID == p.persistentModelID ? 12 : 4,
                                x: 0,
                                y: draggingProspectID == p.persistentModelID ? 6 : 2
                            )
                            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: draggingProspectID)
                            .onDrag {
                                draggingProspectID = p.persistentModelID
                                return NSItemProvider(object: p.fullName as NSString)
                            }
                            .onDrop(of: [.text], delegate: DragResetDelegate {
                                draggingProspectID = nil
                            })
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    prospectToDelete = p
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                            .onTapGesture {
                                selectedProspect = p
                            }
                            .listRowBackground(Color.clear)  // make individual rows’ background transparent
                            // .listRowSeparator(.hidden)
                    }
                    .onMove(perform: moveProspects)
                    .listRowInsets(EdgeInsets()) // optional, to control spacing like LazyVStack
                }
                .listStyle(.plain)
            } else {
                // Empty state — “No matches” if searching, otherwise “No Prospects/Customers”
                Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "No \(selectedList)"
                     : "No matches")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: tableAreaHeight)
        .sheet(item: $selectedProspect) { p in
            NavigationStack {
                ProspectDetailsView(prospect: p)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("Delete Prospect?", isPresented: $showDeleteConfirmation, presenting: prospectToDelete) { prospect in
            Button("Delete", role: .destructive) {
                deleteProspect(prospect)
            }
            Button("Cancel", role: .cancel) {}
        } message: { prospect in
            Text("Are you sure you want to delete \(prospect.fullName)? This action cannot be undone.")
        }
        .onChange(of: selectedProspect) { newValue in
            guard newValue != nil else { return }

            DispatchQueue.main.async {
                withAnimation {
                    isSearchExpanded = false
                    isSearchFocused = false
                }

                // Clear after collapse so the sheet wins the tap
                searchText = ""
            }
        }
    }
    
    private func moveProspects(from source: IndexSet, to destination: Int) {
        var reordered = filtered
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, prospect) in reordered.enumerated() {
            prospect.orderIndex = index
        }

        try? modelContext.save()
        
        draggingProspectID = nil
    }
    
    private struct DragResetDelegate: DropDelegate {
        let onEnd: () -> Void

        func performDrop(info: DropInfo) -> Bool {
            onEnd()
            return true
        }

        func dropExited(info: DropInfo) {
            onEnd()
        }
    }
    
    private func deleteProspect(_ prospect: Prospect) {
        // Delete appointments linked to the prospect
        for appointment in prospect.appointments {
            modelContext.delete(appointment)
        }
        // Delete prospect itself
        modelContext.delete(prospect)
        try? modelContext.save()

        // Reset state
        if selectedProspect?.id == prospect.id {
            selectedProspect = nil
        }
        prospectToDelete = nil
    }
}
