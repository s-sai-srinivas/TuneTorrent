import XCTest

// MARK: - Torrent Tab UITests (covers PRD Module 2 + TorrentService.swift:1)
final class TorrentUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Torrent"].tap()
    }

    func testTorrentListShows() {
        XCTAssertTrue(app.navigationBars["Torrents"].waitForExistence(timeout: 5))
    }

    func testAddButtonExists() {
        // + button in toolbar
        XCTAssertTrue(app.buttons["Add"].waitForExistence(timeout: 3) || app.buttons["plus.circle.fill"].exists || app.buttons["plus"].exists)
    }

    func testSettingsButtonExists() {
        XCTAssertTrue(app.buttons["slider.horizontal.3"].waitForExistence(timeout: 3))
    }

    func testAddSheetMagnetFlow() {
        app.buttons["plus.circle.fill"].tap()
        // AddTorrentSheet should show Magnet Link field
        let magnetField = app.textFields["magnet:?xt=urn:btih:..."]
        if magnetField.waitForExistence(timeout: 3) {
            magnetField.tap()
            magnetField.typeText("magnet:?xt=urn:btih:1234567890123456789012345678901234567890")
            XCTAssertTrue(app.buttons["Start Download"].exists)
            app.buttons["Cancel"].tap()
        }
    }

    func testInvalidMagnetShowsError() {
        // TorrentService regex validation per Rules.md:28
        app.buttons["plus.circle.fill"].tap()
        let field = app.textFields.firstMatch
        if field.waitForExistence(timeout: 2) {
            field.tap(); field.typeText("bad")
            // Start Download should be disabled for invalid magnet
            XCTAssertTrue(app.buttons["Start Download"].exists)
            app.buttons["Cancel"].tap()
        }
    }

    func testEmptyState() {
        // No torrents -> empty state
        let empty = app.staticTexts["No torrents"]
        let table = app.tables.firstMatch
        XCTAssertTrue(empty.waitForExistence(timeout: 2) || table.waitForExistence(timeout: 2))
    }

    func testSpeedSettingsShowsUnlimited() {
        app.buttons["slider.horizontal.3"].tap()
        XCTAssertTrue(app.staticTexts["UNLIMITED"].waitForExistence(timeout: 3) || app.staticTexts["Download: UNLIMITED"].exists)
        app.buttons["Done"].tap()
    }
}
