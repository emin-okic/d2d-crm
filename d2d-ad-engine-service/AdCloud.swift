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
    let sessionId: String
    let appBuild: String?
    let deviceModel: String?
}

final class CloudKitAdLogger {
    static let shared = CloudKitAdLogger()
    private init() {}

    func log(_ payload: ImpressionPayload) {
        let rec = CKRecord(recordType: "ImpressionEvent")
        rec["adId"] = payload.adId as CKRecordValue
        rec["event"] = payload.event as CKRecordValue
        rec["timestamp"] = payload.timestamp as CKRecordValue
        rec["sessionId"] = payload.sessionId as CKRecordValue
        if let appBuild = payload.appBuild { rec["appBuild"] = appBuild as CKRecordValue }
        if let device = payload.deviceModel { rec["deviceModel"] = device as CKRecordValue }

        AdCloud.db.save(rec) { _, error in
            if let ckErr = error as? CKError {
                // Optionally, add lightweight retry on .networkFailure/.serviceUnavailable
                print("CloudKit save failed: \(ckErr)")
            }
        }
    }
}
