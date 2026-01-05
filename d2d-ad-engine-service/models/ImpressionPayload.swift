//
//  ImpressionPayload.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//
import Foundation


struct ImpressionPayload {
    let adId: String
    let event: String   // "impression" | "click" | "cancel"
    let timestamp: Date
}
