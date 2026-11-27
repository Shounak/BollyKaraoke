import AVFAudio
import Foundation
import Observation

@Observable
final class SampleSongPlayer {
    private static let videoID = "s1LozokQjIg"
    private static let sourceURL = URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
    private static let audioURL = URL.applicationSupportDirectory
        .appending(path: "Downloads", directoryHint: .isDirectory)
        .appending(path: "\(videoID).m4a")

    private(set) var isLoading = false
    private(set) var isPlaying = false
    private(set) var error: String?
    var pitchSemitones = 0.0 {
        didSet { timePitch.pitch = Float(pitchSemitones * 100) }
    }
    var tempoPercent = 100.0 {
        didSet { timePitch.rate = Float(tempoPercent / 100) }
    }

    private var hasAudio = FileManager.default.fileExists(atPath: SampleSongPlayer.audioURL.path)
    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let player = AVAudioPlayerNode()
    @ObservationIgnored private let timePitch = AVAudioUnitTimePitch()
    @ObservationIgnored private var audioFile: AVAudioFile?
    @ObservationIgnored private var scheduledPlayback: UUID?

    init() {
        engine.attach(player)
        engine.attach(timePitch)
    }

    var buttonTitle: String {
        if isLoading { return "Downloading…" }
        if isPlaying { return "Pause" }
        return hasAudio ? "Play" : "Download and Play"
    }

    func togglePlayback() async {
        guard !isLoading else { return }
        error = nil

        if engine.isRunning, player.isPlaying {
            player.pause()
            engine.pause()
            isPlaying = false
            return
        }

        do {
            let file: AVAudioFile
            if let audioFile {
                file = audioFile
            } else {
                isLoading = true
                defer { isLoading = false }
                file = try await loadAudio()
                try engine.connectNode(player, to: timePitch, format: file.processingFormat)
                try engine.connectNode(timePitch, to: engine.mainMixerNode, format: file.processingFormat)
                audioFile = file
                hasAudio = true
            }

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
            if !engine.isRunning {
                try engine.start()
            }
            if scheduledPlayback == nil {
                schedule(file)
            }
            try player.playAudio()
            isPlaying = true
        } catch {
            stopPlayback()
            self.error = error.localizedDescription
            print("Sample song: \(error)")
        }
    }

    private func schedule(_ file: AVAudioFile) {
        let playback = UUID()
        scheduledPlayback = playback
        player.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { @Sendable [weak self] _ in
            guard let self else { return }
            // Stopping the node from inside its completion handler can deadlock.
            Task { @MainActor in
                guard self.scheduledPlayback == playback else { return }
                self.stopPlayback()
            }
        }
    }

    private func stopPlayback() {
        scheduledPlayback = nil
        player.stop()
        engine.pause()
        isPlaying = false
    }

    private func loadAudio() async throws -> AVAudioFile {
        let fileManager = FileManager.default
        let savedAudio = Self.audioURL
        if let existing = try? AVAudioFile(forReading: savedAudio), existing.length > 0 {
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
        return try AVAudioFile(forReading: savedAudio)
    }

    private enum PlaybackError: LocalizedError {
        case cannotPlay

        var errorDescription: String? { "The downloaded audio could not be played." }
    }
}
