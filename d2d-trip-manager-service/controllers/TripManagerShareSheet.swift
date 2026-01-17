//
//  ShareSheet.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/17/26.
//


import SwiftUI
import UIKit

struct TripManagerShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
