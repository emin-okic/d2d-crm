//
//  ObjectionsSectionView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import SwiftUI
import SwiftData

struct ObjectionsSectionView: View {
    @Query private var objections: [Objection]
    @State private var selectedObjection: Objection?
    @State private var showingAddObjection = false

    var body: some View {
        ZStack {
            // CONTENT pinned to top-left
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // Header (no add button here anymore)
                    HStack {
                        Text("Biggest Objections")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    if objections.isEmpty {
                        Text("No objections recorded yet.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                    } else {
                        let ranked = objections
                            .filter { $0.text != "Converted To Sale" }
                            .sorted { $0.timesHeard > $1.timesHeard }
                            .enumerated()
                            .map { RankedObjection(rank: $0.offset + 1, objection: $0.element) }

                        VStack(spacing: 0) {
                            ForEach(ranked) { ranked in
                                Button {
                                    selectedObjection = ranked.objection
                                } label: {
                                    HStack {
                                        Text("#\(ranked.rank)")
                                            .frame(width: 40, alignment: .leading)
                                        VStack(alignment: .leading) {
                                            Text(ranked.objection.text)
                                                .font(.headline)
                                        }
                                        .padding(.vertical, 10)
                                        Spacer()
                                        Text("×\(ranked.objection.timesHeard)")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 20)
                                }

                                Divider()
                                    .padding(.leading, 60) // aligns with text stack
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 12)
            }

            // Floating bottom-left toolbar (matches your other screens)
            VStack(spacing: 12) {
                Button {
                    showingAddObjection = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 4)
                }
            }
            .padding(.bottom, 30)
            .padding(.leading, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .zIndex(999)
        }
        .sheet(item: $selectedObjection) { obj in
            ObjectionDetailsView(objection: obj)
        }
        .sheet(isPresented: $showingAddObjection) {
            AddObjectionView()
        }
        .onAppear {
            print("📦 Loaded objections: \(objections.map(\.text))")
        }
    }
}
