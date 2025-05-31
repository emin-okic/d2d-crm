//
//  ImportExportController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation

struct ImportExportController {
    static func buildCSV(from places: [IdentifiablePlace]) -> String {
        var csv = "Address,Latitude,Longitude,Count\n"
        for place in places {
            let line = "\"\(place.address)\",\(place.location.latitude),\(place.location.longitude),\(place.count)"
            csv.append("\(line)\n")
        }
        return csv
    }

    static func saveCSVFile(content: String, fileName: String = "Knocks.csv") -> URL? {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
        let url = tempDir.appendingPathComponent(fileName)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error writing CSV: \(error)")
            return nil
        }
    }
}

