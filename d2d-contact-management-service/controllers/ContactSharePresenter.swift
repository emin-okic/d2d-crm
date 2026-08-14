//
//  ContactSharePresenter.swift
//  d2d-studio
//

import Foundation

struct ContactSharePayload: Identifiable {
    let id = UUID()
    let message: String
}

enum ContactSharePresenter {
    static func payload(fullName: String, address: String, phone: String, email: String) -> ContactSharePayload? {
        var components = URLComponents()
        components.scheme = "d2dcrm"
        components.host = "import"
        components.queryItems = [
            URLQueryItem(name: "fullName", value: fullName),
            URLQueryItem(name: "address", value: address),
            URLQueryItem(name: "phone", value: phone),
            URLQueryItem(name: "email", value: email)
        ]

        guard let deepLink = components.url else {
            print("Failed to generate contact deep link")
            return nil
        }

        let appStoreURL = URL(string: "https://apps.apple.com/us/app/d2d-studio/id6748091911")!
        let message = """
        Check out this contact in D2D Studio CRM!

        Download the app:
        \(appStoreURL.absoluteString)

        Then tap this link to import:
        \(deepLink.absoluteString)
        """

        return ContactSharePayload(message: message)
    }
}
