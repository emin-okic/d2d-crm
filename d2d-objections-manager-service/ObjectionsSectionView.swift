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
                            toggleSelection(objection)
                        } else {
                            selectedObjection = objection
                        }
                    }
                }
                .padding(.top)
            }

            floatingActions
        }
        .sheet(item: $selectedObjection) {
            ObjectionDetailsView(objection: $0)
        }
        .sheet(isPresented: $showingAddObjection) {
            AddObjectionView()
        }
        .alert("Delete selected objections?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteSelected() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Floating Actions
    private var floatingActions: some View {
        VStack(spacing: 12) {
            Button {
                showingAddObjection = true
            } label: {
                floatingIcon("plus", color: .blue)
            }

            Button {
                if isEditing && !selectedObjections.isEmpty {
                    showDeleteConfirm = true
                } else {
                    isEditing.toggle()
                }
            } label: {
                floatingIcon("trash.fill", color: isEditing ? .red : .blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private func floatingIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(Circle().fill(color))
            .shadow(radius: 4)
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
