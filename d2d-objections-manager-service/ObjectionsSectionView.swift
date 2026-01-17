//
//  ObjectionsSectionView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import SwiftUI
import SwiftData

struct ObjectionsSectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var objections: [Objection]

    @State private var selectedObjection: Objection?
    @State private var showingAddObjection = false

    @State private var isEditing = false
    @State private var selectedObjections: Set<Objection> = []
    @State private var showDeleteConfirm = false

    private var rankedObjections: [RankedObjection] {
        objections
            .filter { $0.text != "Converted To Sale" }
            .sorted { $0.timesHeard > $1.timesHeard }
            .enumerated()
            .map { RankedObjection(rank: $0.offset + 1, objection: $0.element) }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    LeaderboardHeaderView(total: rankedObjections.count)

                    ObjectionsLeaderboardView(
                        ranked: rankedObjections,
                        isEditing: isEditing,
                        selected: selectedObjections
                    ) { objection in
                        if isEditing {
                            
                            // DELETE / MULTI-SELECT MODE
                            RecordingScreenHapticsController.shared.mediumTap()
                            RecordingScreenSoundController.shared.playSound1()
                            
                            toggleSelection(objection)
                        } else {
                            
                            // NORMAL MODE: open objection details
                            RecordingScreenHapticsController.shared.lightTap()
                            RecordingScreenSoundController.shared.playSound1()
                            
                            selectedObjection = objection
                        }
                    }
                }
                .padding(.top)
            }

            ObjectionScreenToolbar(
                onAddTapped: { showingAddObjection = true },
                isDeleting: $isEditing,
                selectedCount: selectedObjections.count,
                onDeleteConfirmed: {
                    showDeleteConfirm = true
                }
            )
        }
        .sheet(item: $selectedObjection) {
            ObjectionDetailsView(objection: $0)
        }
        .sheet(isPresented: $showingAddObjection) {
            AddObjectionView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Delete selected objections?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                
                // NORMAL MODE: open objection details
                RecordingScreenHapticsController.shared.lightTap()
                RecordingScreenSoundController.shared.playSound1()
                
                deleteSelected()
                
            }
            Button("Cancel", role: .cancel) {
                
                // NORMAL MODE: open objection details
                RecordingScreenHapticsController.shared.lightTap()
                RecordingScreenSoundController.shared.playSound1()
                
            }
        }
    }


    // MARK: - Helpers
    private func toggleSelection(_ obj: Objection) {
        if selectedObjections.contains(obj) {
            selectedObjections.remove(obj)
        } else {
            selectedObjections.insert(obj)
        }
    }

    private func deleteSelected() {
        selectedObjections.forEach { modelContext.delete($0) }
        try? modelContext.save()
        selectedObjections.removeAll()
        isEditing = false
    }
}
