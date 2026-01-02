//
//  CloudKitEmailLogger.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/2/26.
//

import CloudKit

@MainActor
final class CloudKitEmailLogger {
    static let shared = CloudKitEmailLogger()
    private init() {}

    func log(_ payload: ExportEmailPayload) {
        let record = CKRecord(recordType: "ExportEmailEvent")

        record["email"] = payload.email as CKRecordValue
        record["timestamp"] = payload.timestamp as CKRecordValue
        record["source"] = payload.source as CKRecordValue

        AdCloud.db.save(record) { _, error in
            if let error {
                print("❌ Email save failed:", error)
            } else {
                print("✅ Email captured:", payload.email)
            }
        }
    }
}
