//
//  UnitSelectorPopupView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//

import SwiftUI

struct UnitSelectorPopupView: View {
    let baseAddress: String
    let units: [String?: [UnitContact]]
    let onSelectUnit: (String?, [UnitContact]) -> Void
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
                    
                    ForEach(units.keys.sorted { ($0 ?? "") < ($1 ?? "") }, id: \.self) { key in
                        let contacts = units[key] ?? []
                        Button {
                            onSelectUnit(key, contacts)
                        } label: {
                            HStack {
                                Text(key.map { "Unit \($0)" } ?? "Main")
                                    .font(.headline)

                                Spacer()

                                if contacts.count > 1 {
                                    Text("\(contacts.count)")
                                        .font(.caption.bold())
                                        .padding(6)
                                        .background(Color.secondary.opacity(0.15))
                                        .clipShape(Circle())
                                }

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
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

    private func unitLabel(for address: String) -> String {
        parseAddress(address).unit.map { "Unit \($0)" } ?? "Main"
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
