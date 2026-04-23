import XCTest

final class GiphyDemoScreenshots: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Disable animations so the UI settles instantly.
        app.launchArguments += ["-UIAnimationDragCoefficient", "0"]
    }

    // MARK: - Helpers

    private func save(_ name: String) {
        let screenshot = app.screenshot()
        let att = XCTAttachment(screenshot: screenshot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
        print("📸 \(name)")
    }

    // MARK: - Screenshots

    /// Capture the empty state (no API key configured).
    func testEmptyState() throws {
        app.launch()
        _ = app.navigationBars["Giphy Demo"].waitForExistence(timeout: 5)
        save("ios_empty_state")
    }

    /// Capture the GIF grid populated by MOCK_GIFS (no network needed).
    func testGIFGrid() throws {
        app.launchEnvironment["MOCK_GIFS"] = "1"
        app.launch()
        _ = app.navigationBars["Giphy Demo"].waitForExistence(timeout: 5)

        let firstCell = app.scrollViews.firstMatch.buttons.firstMatch
        XCTAssert(firstCell.waitForExistence(timeout: 5), "Mock GIF cells did not appear")
        sleep(2)
        save("ios_gif_grid")
    }

    /// Capture the GIF detail sheet by tapping the first mock cell.
    func testGIFDetail() throws {
        app.launchEnvironment["MOCK_GIFS"] = "1"
        app.launch()
        _ = app.navigationBars["Giphy Demo"].waitForExistence(timeout: 5)

        let firstCell = app.scrollViews.firstMatch.buttons.firstMatch
        XCTAssert(firstCell.waitForExistence(timeout: 5), "Mock GIF cells did not appear")
        firstCell.tap()
        sleep(2)
        save("ios_gif_detail")
    }
}
