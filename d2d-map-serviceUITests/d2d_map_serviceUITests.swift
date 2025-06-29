//
//  d2d_map_serviceUITests.swift
//  d2d-map-serviceUITests
//
//  Created by Emin Okic on 5/28/25.
//

import XCTest

final class d2d_map_serviceUITests: XCTestCase {

    @MainActor
    func testStartupScreenScreenshot() throws {
        let app = XCUIApplication()
        app.launch()

        sleep(1) // Wait for UI to settle

        let screenshot = XCUIScreen.main.screenshot()
        saveScreenshot(screenshot, screenName: "startup-screen")
    }

    /// Saves a screenshot using the format: x-screen-screenshot.png (overwrite mode)
    private func saveScreenshot(_ screenshot: XCUIScreenshot, screenName: String) {
        let fileManager = FileManager.default

        // Find your actual repo root (2 levels up from this source file)
        let currentFile = URL(fileURLWithPath: #file) // this test file's path
        let projectRoot = currentFile
            .deletingLastPathComponent() // d2d_map_serviceUITests.swift
            .deletingLastPathComponent() // d2d-map-serviceUITests
            // .deletingLastPathComponent() // your project root

        let mediaURL = projectRoot.appendingPathComponent("media", isDirectory: true)

        // Ensure the media directory exists
        do {
            try fileManager.createDirectory(at: mediaURL, withIntermediateDirectories: true)
        } catch {
            XCTFail("❌ Could not create media directory: \(error)")
            return
        }

        let fileName = "\(screenName)-screenshot.png"
        let fileURL = mediaURL.appendingPathComponent(fileName)

        do {
            try screenshot.pngRepresentation.write(to: fileURL)
            print("📸 Screenshot saved to: \(fileURL.path)")
        } catch {
            XCTFail("❌ Failed to save screenshot: \(error)")
        }
    }
}
