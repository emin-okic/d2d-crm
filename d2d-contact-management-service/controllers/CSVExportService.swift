//
//  CSVExportService.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/2/26.
//

import Foundation

struct CSVExportService {

    static func exportProspects(_ prospects: [Prospect]) throws -> URL {
        let header = "Full Name,Address,Email,Phone,Knock Count,Latitude,Longitude\n"

        let rows = prospects.map { p -> String in
            let columns: [String] = [
                escape(p.fullName),
                escape(p.address),
                escape(p.contactEmail),
                escape(p.contactPhone),
                String(p.knockCount),
                p.latitude != nil ? String(p.latitude!) : "",
                p.longitude != nil ? String(p.longitude!) : ""
            ]

            return columns.joined(separator: ",")
        }

        return try writeCSV(
            filename: "prospects_export.csv",
            contents: header + rows.joined(separator: "\n")
        )
    }

    static func exportCustomers(_ customers: [Customer]) throws -> URL {
        let header = "Full Name,Address,Email,Phone,Knock Count,Latitude,Longitude\n"

        let rows = customers.map { c -> String in
            let columns: [String] = [
                escape(c.fullName),
                escape(c.address),
                escape(c.contactEmail),
                escape(c.contactPhone),
                String(c.knockCount),
                c.latitude != nil ? String(c.latitude!) : "",
                c.longitude != nil ? String(c.longitude!) : ""
            ]

            return columns.joined(separator: ",")
        }

        return try writeCSV(
            filename: "customers_export.csv",
            contents: header + rows.joined(separator: "\n")
        )
    }

    // MARK: - Helpers

    private static func writeCSV(filename: String, contents: String) throws -> URL {
        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(filename)

        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
