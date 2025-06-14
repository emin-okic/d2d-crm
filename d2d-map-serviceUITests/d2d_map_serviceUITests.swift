//
//  d2d_map_serviceUITests.swift
//  d2d-map-serviceUITests
//
//  Created by Emin Okic on 5/28/25.
//

import XCTest

final class d2d_map_serviceUITests: XCTestCase {

    @MainActor
    func testLoginScreenScreenshot() throws {
        let app = XCUIApplication()
        app.launch()

        sleep(1) // Wait for UI to settle

        let screenshot = XCUIScreen.main.screenshot()
        saveScreenshot(screenshot, screenName: "login-screen")
    }

    /// Saves a screenshot using the format: x-screen-screenshot.png (overwrite mode)
    private func saveScreenshot(_ screenshot: XCUIScreenshot, screenName: String) {
        let mediaPath = "/Users/eminokic/Documents/Dev/d2d-crm/d2d-map-service/media"
        let mediaURL = URL(fileURLWithPath: mediaPath)

        // Ensure the media folder exists
        try? FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: true)

        // Static file name: login-screen-screenshot.png
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
