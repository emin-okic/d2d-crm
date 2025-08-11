//
//  ObjectionSelectorView.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/11/25.
//

import SwiftUI
import SwiftData

struct ObjectionSelectorView: View {
    @Binding var isPresented: Bool
    var onSelect: (Objection) -> Void
    var filter: (Objection) -> Bool = { _ in true }

    @Environment(\.modelContext) private var modelContext
    @Query private var allObjections: [Objection]

    @State private var showAddObjection = false
    @State private var autoLaunchedAdd = false    // NEW

    private var options: [Objection] {
        allObjections
            .filter(filter)
            .sorted { $0.timesHeard > $1.timesHeard }
    }

    var body: some View {
        NavigationView {
            Group {
                if options.isEmpty {
                    // Empty state (rarely visible—Add sheet auto-opens)
                    VStack(spacing: 12) {
                        Text("No objections yet")
                            .font(.headline)
                        Text("Add your first objection to continue.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button {
                            showAddObjection = true
                        } label: {
                            Label("Add Objection", systemImage: "plus")
                        }
                    }
                    .padding()
                } else {
                    List(options) { obj in
                        Button {
                            obj.timesHeard += 1
                            try? modelContext.save()
                            isPresented = false
                            onSelect(obj)
                        } label: {
                            HStack {
                                Text(obj.text).font(.body)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Why not interested?")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddObjection = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Objection")
                    .disabled(showAddObjection)
                }
            }
        }
        // Auto-launch Add when there are none
        .onAppear {
            if options.isEmpty && !autoLaunchedAdd {
                autoLaunchedAdd = true
                // Defer to next runloop to avoid sheet-on-sheet timing issues
                DispatchQueue.main.async { showAddObjection = true }
            }
        }
        .onChange(of: options.count) { _ in
            // If list becomes empty again (e.g., user deleted last), re-open Add
            if options.isEmpty && !showAddObjection {
                showAddObjection = true
            }
        }
        .sheet(isPresented: $showAddObjection, onDismiss: {
            // If user canceled and still none, close the selector to avoid dead-end
            if options.isEmpty {
                isPresented = false
            }
        }) {
            AddObjectionView()
        }
    }
}
