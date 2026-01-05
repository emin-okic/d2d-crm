//
//  Ad.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/23/25.
//


import Foundation
import SwiftUI

public struct Ad: Identifiable, Codable, Equatable {
    public let id: String
    public var title: String
    public var subtitle: String?
    public var body: String?
    public var ctaText: String
    public var destination: URL
    public var iconSystemName: String? // SF Symbol for simple styling
    public var accentColorHex: String? // theming hook
    public var priority: Int           // higher = shown earlier in shuffle
    public var maxImpressionsPerHour: Int? // optional per-ad cap override
    
    public var imageName: String?
    public var tapEntireImage: Bool?

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        ctaText: String,
        destination: URL,
        iconSystemName: String? = nil,
        accentColorHex: String? = nil,
        priority: Int = 0,
        maxImpressionsPerHour: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.ctaText = ctaText
        self.destination = destination
        self.iconSystemName = iconSystemName
        self.accentColorHex = accentColorHex
        self.priority = priority
        self.maxImpressionsPerHour = maxImpressionsPerHour
    }
}
