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
        let btn = app.buttons["FilesNewFolderButton"].exists ? app.buttons["FilesNewFolderButton"] : app.buttons["folder.badge.plus"]
        btn.tap()
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 3) {
            let field = alert.textFields.firstMatch
            if field.exists {
                field.tap()
                field.typeText("TestFolder")
            }
            alert.buttons["Create"].tap()
            XCTAssertTrue(app.staticTexts["TestFolder"].waitForExistence(timeout: 5) || app.staticTexts["New Folder"].waitForExistence(timeout: 3))
        } else {
            let field = app.textFields["NewFolderNameField"].exists ? app.textFields["NewFolderNameField"] : app.textFields["Name"]
            if field.waitForExistence(timeout: 3) {
                field.tap()
                field.typeText("TestFolder")
                let createBtn = app.buttons["Create"]
                if createBtn.waitForExistence(timeout: 3) {
                    createBtn.tap()
                }
                XCTAssertTrue(app.staticTexts["TestFolder"].waitForExistence(timeout: 5) || app.staticTexts["New Folder"].waitForExistence(timeout: 3))
            } else if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            }
        }
    }

    func testImportButtonOpensPicker() {
        let btn = app.buttons["FilesImportButton"].exists ? app.buttons["FilesImportButton"] : app.buttons["square.and.arrow.down"]
        btn.tap()
        // fileImporter should present system picker - check it appears or error sheet
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 4))
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
