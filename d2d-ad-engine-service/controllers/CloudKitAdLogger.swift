//
//  CloudKitAdLogger.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import CloudKit

@MainActor
final class CloudKitAdLogger {
    static let shared = CloudKitAdLogger()
    private init() {}

    func log(_ payload: ImpressionPayload) {
        let rec = CKRecord(recordType: "ImpressionEventV2")
        rec["adId"]      = payload.adId as CKRecordValue
        rec["event"]     = payload.event as CKRecordValue
        rec["timestamp"] = payload.timestamp as CKRecordValue

        AdCloud.db.save(rec) { _, error in
            if let ckErr = error as? CKError {
                print("CloudKit save failed: \(ckErr)")
            } else {
                print("✅ CloudKit save OK: \(payload.event) \(payload.adId)")
            }
        }
    }
}
