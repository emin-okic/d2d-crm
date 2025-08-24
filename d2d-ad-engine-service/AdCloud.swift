//
//  AdCloud.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/24/25.
//

import CloudKit

enum AdCloud {
    static let container = CKContainer(identifier: "iCloud.com.d2d-studio")
    static let db = container.publicCloudDatabase
}

struct ImpressionPayload {
    let adId: String
    let event: String   // "impression" or "click" (dismiss counts as click)
    let timestamp: Date
}

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
