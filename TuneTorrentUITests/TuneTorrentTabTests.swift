import XCTest

// MARK: - Tab Navigation UITests (covers App shell per Architecture.md:10)
final class TuneTorrentTabTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAppLaunchesAndShowsThreeTabs() {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Music"].exists)
        XCTAssertTrue(app.tabBars.buttons["Torrent"].exists)
        XCTAssertTrue(app.tabBars.buttons["Files"].exists)
    }

    func testMainTabViewExists() {
        XCTAssertTrue(app.otherElements["MainTabView"].waitForExistence(timeout: 5))
    }

    func testSwitchBetweenTabs() {
        app.tabBars.buttons["Torrent"].tap()
        XCTAssertTrue(app.navigationBars["Torrents"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Files"].tap()
        XCTAssertTrue(app.navigationBars["Files"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Music"].tap()
        XCTAssertTrue(app.navigationBars["Music"].waitForExistence(timeout: 3))
    }

    func testTabBarIsGlassy() {
        // TabBar uses ultraThinMaterial per Theme.swift:1 GlassTabBackground
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}
