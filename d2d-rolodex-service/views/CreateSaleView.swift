//
//  CreateSaleView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/21/25.
//
import SwiftUI

struct CreateSaleView: View {
    @Bindable var prospect: Prospect
    @Binding var isPresented: Bool

    var body: some View {
        SignUpPopupView(prospect: prospect, isPresented: $isPresented)
    }
}
