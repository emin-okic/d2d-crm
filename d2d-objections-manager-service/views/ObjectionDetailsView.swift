//
//  EditObjectionView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//

import SwiftUI
import SwiftData

struct ObjectionDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var objection: Objection

    @State private var showDeleteAlert = false
    @State private var showRegenerateAlert = false
    
    @State private var showPracticeSheet = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {

                    ObjectionHeaderCard(objection: objection)

                    ObjectionMetricCard(
                        title: "Times Heard",
                        value: objection.timesHeard
                    ) {
                        Stepper("", value: $objection.timesHeard, in: 0...10_000)
                            .labelsHidden()
                    }

                    ObjectionEditableCard(
                        title: "Objection",
                        subtitle: "Exact phrase prospects say",
                        text: $objection.text
                    )

                    ObjectionEditableCard(
                        title: "Expected Response",
                        subtitle: "How you should respond",
                        text: $objection.response,
                        isMultiline: true,
                        trailingAction: {
                            AnyView(
                                Button {
                                    showRegenerateAlert = true
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                            )
                        }
                    )
                    
                    if !objection.extraResponses.isEmpty {
                        SavedResponsesList(responses: objection.extraResponses)
                    }
                    
                    WriteResponseCTA {
                        showPracticeSheet = true
                    }
                    .sheet(isPresented: $showPracticeSheet) {
                        WriteResponsePracticeView(objection: objection)
                    }
                }
                .padding()
                .padding(.bottom, 80) // space for floating delete button
            }

            // 🗑️ Floating Delete Button (Bottom Left)
            VStack {
                Spacer()

                HStack {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                            .background(
                                Circle().fill(Color.red)
                            )
                            .shadow(color: Color.red.opacity(0.4), radius: 6, x: 0, y: 3)
                    }
                    .accessibilityLabel("Delete Objection")

                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Objection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .alert("Delete objection?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(objection)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Regenerate response?", isPresented: $showRegenerateAlert) {
            Button("Regenerate", role: .destructive) {
                Task {
                    objection.response = await ResponseGenerator.shared.generate(for: objection.text)
                    try? modelContext.save()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
