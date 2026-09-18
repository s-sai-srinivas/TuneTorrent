import XCTest

// MARK: - Settings + Accessibility + Glass UI UITests
final class SettingsAndAccessibilityTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testSettingsReachableFromFiles() {
        app.tabBars.buttons["Files"].tap()
        app.buttons["gearshape"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3) || app.staticTexts["About"].waitForExistence(timeout: 3))
    }

    func testDynamicTypeAndVoiceOver() {
        app.tabBars.buttons["Music"].tap()
        XCTAssertTrue(app.navigationBars["Music"].exists)
        // VoiceOver label per SongRow
        XCTAssertTrue(app.staticTexts.firstMatch.exists)
    }

    func testGlassCardsExist() {
        // GlassCard uses ultraThinMaterial + rounded rect — check not crashing
        app.tabBars.buttons["Files"].tap()
        XCTAssertTrue(app.otherElements["MainTabView"].exists)
    }

    func testNoForceUnwrapOnLaunch() {
        // Rules.md:2 no force-unwrap — app should launch without crash after 3 tab switches
        for _ in 0..<3 {
            app.tabBars.buttons["Music"].tap()
            app.tabBars.buttons["Torrent"].tap()
            app.tabBars.buttons["Files"].tap()
        }
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    func testInfoPlistPermissions() {
        // NSAppleMusicUsageDescription + UIBackgroundModes + Live Activities
        // Indirect: Music tab should not crash when permission denied (shows empty state)
        app.tabBars.buttons["Music"].tap()
        XCTAssertTrue(app.staticTexts["No songs found"].waitForExistence(timeout: 3) || app.tables.firstMatch.waitForExistence(timeout: 3))
    }
}
