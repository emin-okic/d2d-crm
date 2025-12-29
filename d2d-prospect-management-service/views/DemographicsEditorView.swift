//
//  DemographicsEditorView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/29/25.
//

import SwiftUI

struct DemographicsEditorView: View {
    @Binding var demographics: Demographics
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Age")) {
                    TextField("Age", value: $demographics.age, format: .number)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Gender")) {
                    Picker("Gender", selection: Binding($demographics.gender, replacingNilWith: "")) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Income Level")) {
                    TextField("Income Level", text: Binding(
                        get: { demographics.incomeLevel ?? "" },
                        set: { demographics.incomeLevel = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section(header: Text("Education")) {
                    TextField("Education",
                              text: Binding(
                                get: { demographics.education ?? "" },
                                set: { demographics.education = $0.isEmpty ? nil : $0 }
                              )
                    )
                }
                
                Section(header: Text("Occupation")) {
                    TextField("Occupation",
                              text: Binding(
                                get: { demographics.occupation ?? "" },
                                set: { demographics.occupation = $0.isEmpty ? nil : $0 }
                              )
                    )
                }
            }
            .navigationTitle("Demographics")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// Helper for optional binding
extension Binding where Value == String? {
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = ($0 ?? "").isEmpty ? nil : $0 }
        )
    }
}
