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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Biggest Objections")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddObjection = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
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
