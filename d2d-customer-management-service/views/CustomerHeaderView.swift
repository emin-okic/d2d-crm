//
//  CustomerHeaderView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/23/25.
//

import SwiftUI

struct CustomerHeaderView: View {
    let totalCustomers: Int

    var body: some View {
        VStack(spacing: 10) {
            Text("Contacts")
                .font(.largeTitle).fontWeight(.bold)
                .padding(.top, 10)

            Text("\(totalCustomers) Customers")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
}
