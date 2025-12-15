//
//  CallActionBottomSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/15/25.
//

import SwiftUI

struct CallActionBottomSheet: View {
    let phone: String
    let onCall: () -> Void
    let onEdit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 16) {
                Text("Call")
                    .font(.headline)

                Text(phone)
                    .font(.title3)
                    .fontWeight(.semibold)

                HStack(spacing: 12) {
                    Button(action: onCall) {
                        Label("Call", systemImage: "phone.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 32)
            .padding(.horizontal)
            .padding(.bottom, 12)

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(8)
        }
    }
}
