import AVFAudio
import Foundation
import Observation

@Observable
final class SampleSongPlayer: NSObject, AVAudioPlayerDelegate {
    private static let videoID = "s1LozokQjIg"
    private static let sourceURL = URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
    private static let audioURL = URL.applicationSupportDirectory
        .appending(path: "Downloads", directoryHint: .isDirectory)
        .appending(path: "\(videoID).m4a")

    private(set) var isLoading = false
    private(set) var isPlaying = false
    private(set) var error: String?
    private var hasAudio = FileManager.default.fileExists(atPath: SampleSongPlayer.audioURL.path)
    @ObservationIgnored private var player: AVAudioPlayer?

    var buttonTitle: String {
        if isLoading { return "Downloading…" }
        if isPlaying { return "Pause" }
        return hasAudio ? "Play" : "Download and Play"
    }

    func togglePlayback() async {
        guard !isLoading else { return }
        error = nil

        if let player, player.isPlaying {
            player.pause()
            isPlaying = false
            return
        }

        do {
            if player == nil {
                isLoading = true
                defer { isLoading = false }
                player = try await loadAudio()
                player?.delegate = self
                hasAudio = true
            }

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
            guard player?.play() == true else { throw PlaybackError.cannotPlay }
            isPlaying = true
        } catch {
            isPlaying = false
            self.error = error.localizedDescription
            print("Sample song: \(error)")
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        player.currentTime = 0
        isPlaying = false
        if !flag {
            error = PlaybackError.cannotPlay.localizedDescription
        }
    }

    private func loadAudio() async throws -> AVAudioPlayer {
        let fileManager = FileManager.default
        let savedAudio = Self.audioURL
        if let existing = try? AVAudioPlayer(contentsOf: savedAudio), existing.duration > 0 {
            return existing
        }

        hasAudio = false
        if fileManager.fileExists(atPath: savedAudio.path) {
            try fileManager.removeItem(at: savedAudio)
        }
        try fileManager.createDirectory(at: savedAudio.deletingLastPathComponent(), withIntermediateDirectories: true)

        let staging = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? fileManager.removeItem(at: staging) }

        let audio = staging.appending(path: "audio.m4a")
        try await YTDLP.downloadAudio(from: Self.sourceURL, to: audio)
        try Task.checkCancellation()
        guard try AVAudioFile(forReading: audio).length > 0 else {
            throw PlaybackError.cannotPlay
        }
        try fileManager.moveItem(at: audio, to: savedAudio)
        return try AVAudioPlayer(contentsOf: savedAudio)
    }

    private enum PlaybackError: LocalizedError {
        case cannotPlay

        var errorDescription: String? { "The downloaded audio could not be played." }
    }
}
