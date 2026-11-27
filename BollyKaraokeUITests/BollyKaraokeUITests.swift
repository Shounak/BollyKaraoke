import XCTest

final class BollyKaraokeUITests: XCTestCase {
    @MainActor
    func testSampleSongAdjustsPitchAndTempoIndependently() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let playback = app.buttons["sample-song-playback"]
        XCTAssertTrue(playback.waitForExistence(timeout: 5))
        XCTAssertTrue(playback.isEnabled)
        XCTAssertEqual(app.buttons.count, 1)
        XCTAssertTrue(app.staticTexts["Mere Khwabon Mein"].exists)

        let pitch = app.sliders["sample-song-pitch"]
        let tempo = app.sliders["sample-song-tempo"]
        XCTAssertEqual(pitch.value as? String, "0 semitones")
        XCTAssertEqual(tempo.value as? String, "100%")

        pitch.adjust(toNormalizedSliderPosition: 0.75)
        let adjustedPitch = pitch.value as? String
        XCTAssertNotEqual(adjustedPitch, "0 semitones")
        XCTAssertEqual(tempo.value as? String, "100%")

        tempo.adjust(toNormalizedSliderPosition: 0.25)
        XCTAssertNotEqual(tempo.value as? String, "100%")
        XCTAssertEqual(pitch.value as? String, adjustedPitch)
    }
}
