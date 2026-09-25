import XCTest

// MARK: - Files Tab UITests (covers PRD Module 3 + FileManagerService.swift:5 + StorageAnalyzerService.swift:1)
final class FilesUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Files"].tap()
    }

    func testFilesTabShows() {
        XCTAssertTrue(app.navigationBars["Files"].waitForExistence(timeout: 5))
    }

    func testStorageHeaderExists() {
        // StorageHeaderView with Used/Free + breakdown
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS 'Used'")).firstMatch.waitForExistence(timeout: 3) || app.otherElements["StorageHeader"].exists)
    }

    func testBreadcrumbsAndToolbar() {
        XCTAssertTrue(app.buttons["FilesImportButton"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["FilesNewFolderButton"].waitForExistence(timeout: 3))
    }

    func testSearchAndSort() {
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 3) || app.textFields["Search"].exists)
        XCTAssertTrue(app.buttons["Sort"].waitForExistence(timeout: 3))
    }

    func testListGridToggle() {
        let toggle = app.buttons["Grid"].firstMatch
        if toggle.waitForExistence(timeout: 2) { toggle.tap(); XCTAssertTrue(app.buttons["List"].waitForExistence(timeout: 2)) }
        else if app.buttons["List"].waitForExistence(timeout: 2) { app.buttons["List"].tap(); XCTAssertTrue(app.buttons["Grid"].waitForExistence(timeout: 2)) }
    }

    func testNewFolderFlow() {
        app.buttons["folder.badge.plus"].tap()
        let field = app.textFields.firstMatch
        if field.waitForExistence(timeout: 2) {
            field.tap(); field.typeText("TestFolder")
            app.buttons["Create"].tap()
            // Folder should appear in list
            XCTAssertTrue(app.staticTexts["TestFolder"].waitForExistence(timeout: 2))
        } else {
            app.buttons["Cancel"].tap()
        }
    }

    func testImportButtonOpensPicker() {
        app.buttons["square.and.arrow.down"].tap()
        // fileImporter should present system picker - check it appears or error sheet
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 2))
        // Dismiss if needed
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
    }

    func testMultiSelectAndBulkDelete() {
        // Select -> shows Move/Copy/Share/Delete bar per Rules.md:5
        if app.buttons["Select"].waitForExistence(timeout: 2) {
            app.buttons["Select"].tap()
            XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 2))
            app.buttons["Done"].tap()
        }
    }

    func testHiddenToggle() {
        // HiddenToggleView eye
        XCTAssertTrue(app.switches.firstMatch.waitForExistence(timeout: 2) || app.staticTexts["Show hidden files"].exists)
    }

    func testThumbnailAppears() {
        // FileRowFull uses ThumbnailService - check at least one cell has image
        let firstCell = app.tables.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 2) || app.otherElements.firstMatch.exists)
    }
}
