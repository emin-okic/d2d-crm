//
//  NewProspectView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//
import SwiftUI
import MapKit

struct NewProspectView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedList: String
    var onSave: () -> Void

    @State private var fullName = ""
    @State private var address = ""
    @State private var contactPhone = ""
    @State private var contactEmail = ""

    @StateObject private var searchVM = SearchCompleterViewModel()
    @FocusState private var isAddressFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Prospect Info")) {
                    TextField("Full Name", text: $fullName)

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Address", text: $address)
                            .focused($isAddressFocused)
                            .onChange(of: address) { searchVM.updateQuery($0) }

                        if isAddressFocused && !searchVM.results.isEmpty {
                            ForEach(searchVM.results.prefix(3), id: \.self) { result in
                                Button {
                                    handleAddressSelection(result)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(result.title).bold()
                                        Text(result.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                    }

                    TextField("Phone (Optional)", text: $contactPhone)
                        .keyboardType(.phonePad)

                    TextField("Email (Optional)", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add Prospect")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newProspect = Prospect(
                            fullName: fullName,
                            address: address,
                            count: 0,
                            list: selectedList
                        )
                        newProspect.contactPhone = contactPhone
                        newProspect.contactEmail = contactEmail
                        modelContext.insert(newProspect)
                        onSave()
                    }
                    .disabled(fullName.isEmpty || address.isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onSave()
                    }
                }
            }
        }
    }

    private func handleAddressSelection(_ result: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: result)
        MKLocalSearch(request: request).start { response, error in
            guard let item = response?.mapItems.first else { return }

            DispatchQueue.main.async {
                address = item.placemark.title ?? result.title
                searchVM.results = []
                isAddressFocused = false
            }
        }
    }
}
