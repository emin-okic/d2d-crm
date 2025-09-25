//
//  CustomerSectionView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/25/25.
//

import SwiftUI
import SwiftData

struct CustomerSectionView: View {
    @Binding var selectedList: String
    let containerHeight: CGFloat
    var searchText: String

    @Query private var customers: [Customer]

    init(selectedList: Binding<String>, containerHeight: CGFloat, searchText: String) {
        self._selectedList = selectedList
        self.containerHeight = containerHeight
        self.searchText = searchText
        self._customers = Query(
            filter: #Predicate<Customer> { customer in
                searchText.isEmpty ||
                customer.fullName.localizedStandardContains(searchText) ||
                customer.address.localizedStandardContains(searchText)
            },
            sort: [SortDescriptor(\Customer.fullName, order: .forward)]
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(customers) { customer in
                    NavigationLink(destination: CustomerDetailsView(customer: customer)) {
                        CustomerRowView(customer: customer)
                            .padding(.horizontal, 4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain) // so it looks like your row, not a default blue link
                }
            }
            .frame(minHeight: containerHeight, alignment: .top)
        }
    }
}
