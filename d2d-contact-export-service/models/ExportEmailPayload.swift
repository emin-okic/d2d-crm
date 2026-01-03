//
//  ExportEmailPayload.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/2/26.
//

import CloudKit

struct ExportEmailPayload {
    let email: String
    let timestamp: Date
    let source: String // "csv_export_gate"
}
