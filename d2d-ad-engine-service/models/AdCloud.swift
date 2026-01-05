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
