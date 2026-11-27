import XCTest

final class BollyKaraokeUITests: XCTestCase {
    @MainActor
    func testSampleSongShowsPlaybackControl() {
        let app = XCUIApplication()
        app.launch()

        let playback = app.buttons["sample-song-playback"]
        XCTAssertTrue(playback.waitForExistence(timeout: 5))
        XCTAssertTrue(playback.isEnabled)
        XCTAssertEqual(app.buttons.count, 1)
        XCTAssertTrue(app.staticTexts["Mere Khwabon Mein"].exists)
    }
}
