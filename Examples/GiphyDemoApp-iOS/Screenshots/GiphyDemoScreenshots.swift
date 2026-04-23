import XCTest

final class GiphyDemoScreenshots: XCTestCase {

    private let apiKey = "nxQrYdLrix5EyywZom3K9BrITqiY7XXd"
    private let searchTerm = "cat"

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Disable animations so the UI settles instantly.
        app.launchArguments += ["-UIAnimationDragCoefficient", "0"]
        // Inject live API key so DemoViewModel reads it from ProcessInfo.environment.
        app.launchEnvironment["GIPHY_API_KEY"] = apiKey
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

    /// Type into the search field, tap Search, and dismiss the keyboard.
    private func searchFor(_ term: String) {
        let searchField = app.textFields["search_field"]
        XCTAssert(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText(term)
        app.buttons["search_button"].tap()
        // Dismiss keyboard so it doesn't appear in the screenshot.
        if app.keyboards.firstMatch.exists {
            app.tap()
        }
    }

    // MARK: - Screenshots

    /// Capture the trending GIF grid that loads automatically on launch.
    func testTrendingGrid() throws {
        app.launch()
        _ = app.navigationBars["Giphy Demo"].waitForExistence(timeout: 5)
        // Trending loads automatically — wait up to 30s for the first cell.
        let firstCell = app.buttons.matching(identifier: "gif_cell").firstMatch
        let appeared = firstCell.waitForExistence(timeout: 30)
        if appeared { sleep(8) } // let thumbnails download
        save("ios_trending_grid")
        XCTAssert(appeared, "Trending GIF cells did not appear")
    }

    /// Search for "\(searchTerm)" and capture the results grid.
    func testSearchResults() throws {
        app.launch()
        _ = app.navigationBars["Giphy Demo"].waitForExistence(timeout: 5)
        searchFor(searchTerm)
        let firstCell = app.buttons.matching(identifier: "gif_cell").firstMatch
        let appeared = firstCell.waitForExistence(timeout: 30)
        if appeared { sleep(8) } // let thumbnails download
        save("ios_search_results")
        XCTAssert(appeared, "Search result cells did not appear")
    }

    /// Open the detail sheet for the first search result.
    func testGIFDetail() throws {
        app.launch()
        _ = app.navigationBars["Giphy Demo"].waitForExistence(timeout: 5)
        searchFor(searchTerm)
        let firstCell = app.buttons.matching(identifier: "gif_cell").firstMatch
        let appeared = firstCell.waitForExistence(timeout: 30)
        if appeared {
            sleep(8) // let thumbnails download
            firstCell.tap()
            sleep(10) // let original GIF download
        }
        save("ios_gif_detail")
        XCTAssert(appeared, "Search result cells did not appear")
    }
}
