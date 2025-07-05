//
//  KnockDotsView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/19/25.
//
import SwiftUI
import SwiftData

struct KnockDotsView: View {
    let knocks: [Knock]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(knocks.prefix(5), id: \.date) { knock in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(knock.status == "Answered" ? .green : .red)
            }
        }
        .padding(.top, 4)
    }
}
