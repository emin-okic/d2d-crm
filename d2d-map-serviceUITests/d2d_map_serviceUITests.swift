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

        // Wait a second for the login UI to settle
        sleep(1)

        // Take screenshot of the current screen (login view)
        let screenshot = XCUIScreen.main.screenshot()

        // Save it to Media/LoginScreen.png
        saveScreenshot(screenshot, named: "LoginScreen")
    }

    /// Saves a screenshot PNG file to the Media directory in your project
    private func saveScreenshot(_ screenshot: XCUIScreenshot, named name: String) {
        let mediaPath = "/Users/eminokic/Documents/Dev/d2d-crm/d2d-map-service/media"
        let mediaURL = URL(fileURLWithPath: mediaPath)

        // Create folder if it doesn't exist
        try? FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: true)

        let fileURL = mediaURL.appendingPathComponent("\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: fileURL)
            print("📸 Screenshot saved to: \(fileURL.path)")
        } catch {
            XCTFail("❌ Failed to save screenshot: \(error)")
        }
    }
}
