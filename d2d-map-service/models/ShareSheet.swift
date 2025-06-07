//
//  ShareSheet.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/29/25.
//

import UIKit
import SwiftUI

/// A SwiftUI wrapper for `UIActivityViewController`, allowing content to be shared
/// via standard iOS share sheet options (e.g., AirDrop, Messages, Mail, Notes).
///
/// Example usage:
/// ```swift
/// ShareSheet(activityItems: ["Hello from D2D!"])
/// ```
struct ShareSheet: UIViewControllerRepresentable {

    /// The items to share, such as text, images, or URLs.
    let activityItems: [Any]

    /// Creates the `UIActivityViewController` using the given items.
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    /// Required but unused in this case, as there's no need to update the view controller after creation.
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
