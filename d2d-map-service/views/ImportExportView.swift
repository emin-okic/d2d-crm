//
//  ImportExportView.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    var markers: [IdentifiablePlace]
    var onImport: (URL) -> Void

    @State private var showShareSheet = false
    @State private var csvURL: URL? = nil
    @State private var isImporterPresented = false

    var body: some View {
        HStack {
            Button {
                let csvText = buildCSV(from: markers)
                if let fileURL = saveCSVFile(content: csvText) {
                    self.csvURL = fileURL
                    self.showShareSheet = true
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(markers.isEmpty ? .gray : .blue)
            }
            .disabled(markers.isEmpty)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8)
                            .stroke(markers.isEmpty ? Color.gray : Color.blue, lineWidth: 1))
            .shadow(radius: 2, x: 0, y: 1)
            .sheet(isPresented: $showShareSheet) {
                if let fileURL = csvURL {
                    ShareSheet(activityItems: [fileURL])
                }
            }

            Spacer().frame(width: 8)

            Button {
                isImporterPresented = true
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .shadow(radius: 2, x: 0, y: 1)
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        onImport(url)
                    }
                case .failure(let error):
                    print("File import failed: \(error)")
                }
            }
        }
    }

    private func buildCSV(from places: [IdentifiablePlace]) -> String {
        var csv = "Address,Latitude,Longitude,Count\n"
        for place in places {
            let line = "\"\(place.address)\",\(place.location.latitude),\(place.location.longitude),\(place.count)"
            csv.append("\(line)\n")
        }
        return csv
    }

    private func saveCSVFile(content: String, fileName: String = "Knocks.csv") -> URL? {
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
