//
//  AdDemoInventory.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/23/25.
//

import Foundation

@MainActor
public enum AdDemoInventory {
    public static var defaultAds: [Ad] = {
        let funnelURL = URL(string: "https://www.clickfunnels.com/signup-flow?aff=ee8160b4...7995")!

        return [
            Ad(
                id: "cf-any-business",
                title: "Literally Any Business Needs a Funnel",
                subtitle: nil,
                body: nil,
                ctaText: "Free 14-Day Trial",
                destination: funnelURL,
                iconSystemName: nil,
                accentColorHex: nil,
                priority: 10,
                maxImpressionsPerHour: 1
            ).withImage("Literally_Any_Business_300x250"),

            Ad(
                id: "cf-page-builders-suck",
                title: "Page Builders Suck!",
                ctaText: "Free 14-Day Trial",
                destination: funnelURL,
                priority: 9
            ).withImage("Page_Builders_Suck_320x200"),

            Ad(
                id: "cf-save-your-business",
                title: "Save Your Business — Abandon Your Website",
                ctaText: "Free 14-Day Trial",
                destination: funnelURL,
                priority: 8
            ).withImage("Save_Your_Business_320x200"),

            Ad(
                id: "cf-stop-trying-to-code",
                title: "Stop Trying To Code Your Website",
                ctaText: "Free 14-Day Trial",
                destination: funnelURL,
                priority: 7
            ).withImage("Stop_Trying_to_Code_320x200"),

            Ad(
                id: "cf-stop-trying-to-code-biz-site",
                title: "Stop Trying To Code Your Business’ Site",
                ctaText: "Free 14-Day Trial",
                destination: funnelURL,
                priority: 6
            ).withImage("Stop_Trying_to_Code_Your_Business_Website_320x200"),

            Ad(
                id: "cf-only-builder",
                title: "The Only Website Builder That Builds Entire Sales Funnels!",
                ctaText: "Watch Video",
                destination: funnelURL,
                priority: 5
            ).withImage("The_Only_Website_Builder_300x250"),
        ]
    }()
}

// Tiny helper to keep your model immutable-by-default.
private extension Ad {
    func withImage(_ name: String, tapEntireImage: Bool = true) -> Ad {
        var copy = self
        copy.imageName = name
        copy.tapEntireImage = tapEntireImage
        return copy
    }
}
