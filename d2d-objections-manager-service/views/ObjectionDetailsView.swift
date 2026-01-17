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
                            .onChange(of: objection.timesHeard) { _ in
                                // Haptics + sound when counter changes
                                ObjectionManagerHapticsController.shared.screenTap()
                                ObjectionManagerSoundController.shared.playActionSound()
                            }
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
                                    
                                    // Haptics + sound when tapping the regenerate button
                                    ObjectionManagerHapticsController.shared.actionConfirmation()
                                    ObjectionManagerSoundController.shared.playActionSound()
                                    
                                    showRegenerateAlert = true
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                            )
                        }
                    )
                    
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
                        
                        // Haptics + sound when tapping the delete button
                        ObjectionManagerHapticsController.shared.actionConfirmation()
                        ObjectionManagerSoundController.shared.playActionSound()
                        
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
                
                // Haptics + sound when tapping the delete button
                ObjectionManagerHapticsController.shared.actionConfirmation()
                ObjectionManagerSoundController.shared.playActionSound()
                
                modelContext.delete(objection)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                
                // Haptics + sound when tapping the delete button
                ObjectionManagerHapticsController.shared.actionConfirmation()
                ObjectionManagerSoundController.shared.playActionSound()
                
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Regenerate response?", isPresented: $showRegenerateAlert) {
            Button("Regenerate", role: .destructive) {
                
                // Haptics + sound when confirming regenerate
                ObjectionManagerHapticsController.shared.actionConfirmation()
                ObjectionManagerSoundController.shared.playActionSound()
                
                Task {
                    let generated = await ResponseGenerator.shared.generate(for: objection.text)
                    objection.addResponse(generated)  // add to the set
                    objection.rotateResponse()         // rotate to a random response
                    try? modelContext.save()
                }
            }
            Button("Cancel", role: .cancel) {
                
                // Haptics + sound when confirming regenerate
                ObjectionManagerHapticsController.shared.actionConfirmation()
                ObjectionManagerSoundController.shared.playActionSound()
                
            }
        }
    }
}
