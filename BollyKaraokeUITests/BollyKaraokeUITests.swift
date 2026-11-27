import XCTest

final class BollyKaraokeUITests: XCTestCase {
    @MainActor
    func testVersionButtonReportsBundledYTDLPVersion() {
        let app = XCUIApplication()
        app.launch()

        let button = app.buttons["Check yt-dlp version"]
        let output = app.staticTexts["yt-dlp-output"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        XCTAssertFalse(output.exists)

        button.tap()
        XCTAssertTrue(output.waitForExistence(timeout: 10))
        let version = output.label
        XCTAssertTrue(version.range(of: #"^\d{4}\.\d{1,2}\.\d{1,2}(\.\d+)?$"#, options: .regularExpression) != nil, version)

        button.tap()
        XCTAssertEqual(output.label, version)
    }
}
