//
//  MarkerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 7/18/25.
//
import SwiftUI
import MapKit
import CoreLocation
import SwiftData
import Combine
import Contacts

struct MarkerView: View {
    let place: IdentifiablePlace

    var body: some View {
        Group {
            if place.list == "Customers" {
                Image(systemName: "star.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
            } else {
                Circle()
                    .fill(place.markerColor)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1))
            }
        }
    }
}
