import XCTest

final class BollyKaraokeUITests: XCTestCase {
    @MainActor
    func testLibraryOpensPlayerAndRemembersPracticeSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Your library"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["featured-song"].exists)
        let search = app.textFields["library-search"]
        search.tap()
        search.typeText("zzzz")
        XCTAssertTrue(app.staticTexts["No matching downloads"].exists)
        app.buttons["Clear search"].tap()

        app.buttons["search-tab"].tap()
        XCTAssertTrue(app.textFields["youtube-search"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Search YouTube"].exists)

        app.buttons["Player"].tap()
        let playback = app.buttons["sample-song-playback"]
        XCTAssertTrue(playback.waitForExistence(timeout: 5))
        XCTAssertTrue(playback.isEnabled)
        XCTAssertTrue(app.staticTexts["Mere Khwabon Mein"].exists)

        let reset = app.buttons["Reset practice settings"]
        if reset.exists {
            reset.tap()
        }
        let pitch = app.sliders["sample-song-pitch"]
        let tempo = app.sliders["sample-song-tempo"]
        XCTAssertEqual(pitch.value as? String, "0 semitones")
        XCTAssertEqual(tempo.value as? String, "100%")

        pitch.adjust(toNormalizedSliderPosition: 0.75)
        let adjustedPitch = pitch.value as? String
        XCTAssertNotEqual(adjustedPitch, "0 semitones")
        XCTAssertEqual(tempo.value as? String, "100%")

        tempo.adjust(toNormalizedSliderPosition: 0.25)
        let adjustedTempo = tempo.value as? String
        XCTAssertNotEqual(adjustedTempo, "100%")
        XCTAssertEqual(pitch.value as? String, adjustedPitch)

        app.terminate()
        app.launch()
        app.buttons["Player"].tap()
        XCTAssertEqual(pitch.value as? String, adjustedPitch)
        XCTAssertEqual(tempo.value as? String, adjustedTempo)
        reset.tap()
        XCTAssertEqual(pitch.value as? String, "0 semitones")
        XCTAssertEqual(tempo.value as? String, "100%")
    }
}
