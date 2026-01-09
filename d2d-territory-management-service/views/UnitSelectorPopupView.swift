//
//  UnitSelectorPopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI

struct UnitSelectorPopupView: View {
    let baseAddress: String
    let units: [UnitContact]
    let onSelect: (UnitContact) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .imageScale(.large)
                }
            }

            Text(baseAddress)
                .font(.headline)
                .multilineTextAlignment(.center)

            Divider()

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(units) { unit in
                        Button {
                            onSelect(unit)
                        } label: {
                            HStack {
                                Text(unitLabel(for: unit))
                                    .font(.headline)

                                if unit.isUnqualified {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 18, height: 18)

                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                else if unit.isCustomer {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .frame(width: 280, height: 320)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(radius: 8)
    }

    private func unitLabel(for unit: UnitContact) -> String {
        if let unitNumber = parseAddress(unit.address).unit {
            return "Unit \(unitNumber)"
        } else {
            // Use the Prospect/Customer fullName
            switch unit {
            case .prospect(let p):
                return p.fullName
            case .customer(let c):
                return c.fullName
            }
        }
    }
}
