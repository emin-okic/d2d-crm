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
        // Get project root by walking up 2 directories from test bundle location
        let testBundlePath = Bundle(for: Self.self).bundlePath
        let projectRoot = URL(fileURLWithPath: testBundlePath)
            .deletingLastPathComponent() // d2d-map-serviceUITests.xctest
            .deletingLastPathComponent() // d2d-map-service

        let mediaURL = projectRoot.appendingPathComponent("media", isDirectory: true)

        // Ensure the media directory exists
        try? FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: true)

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
