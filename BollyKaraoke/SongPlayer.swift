import AVFAudio
import Foundation
import Observation

@Observable
final class SongPlayer {
    let library: SongLibrary
    private(set) var track: LibraryTrack
    private(set) var isLoading = false
    private(set) var isPlaying = false
    private(set) var error: String?
    var settings: PracticeSettings {
        didSet {
            applySettings()
            library.save(settings, for: track.id)
        }
    }

    private var position: TimeInterval = 0
    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let player = AVAudioPlayerNode()
    @ObservationIgnored private let timePitch = AVAudioUnitTimePitch()
    @ObservationIgnored private var audioFile: AVAudioFile?
    @ObservationIgnored private var scheduledPlayback: UUID?
    @ObservationIgnored private var segmentStart: TimeInterval = 0

    init(library: SongLibrary) {
        self.library = library
        let track = library.downloads.first ?? .sample
        self.track = track
        settings = library.settings(for: track.id)
        engine.attach(player)
        engine.attach(timePitch)
        applySettings()
    }

    var currentTime: TimeInterval {
        guard isPlaying, let nodeTime = player.lastRenderTime,
              let time = player.playerTime(forNodeTime: nodeTime), time.sampleRate > 0 else {
            return position
        }
        return min(track.duration, segmentStart + Double(time.sampleTime) / time.sampleRate)
    }

    func select(_ track: LibraryTrack) {
        guard !isLoading, self.track.id != track.id else { return }
        stopPlayback()
        audioFile = nil
        position = 0
        error = nil
        self.track = track
        settings = library.settings(for: track.id)
    }

    func togglePlayback() async {
        guard !isLoading else { return }
        error = nil

        if engine.isRunning, player.isPlaying {
            position = currentTime
            player.pause()
            engine.pause()
            isPlaying = false
            return
        }

        do {
            if audioFile == nil {
                isLoading = true
                defer { isLoading = false }
                let downloaded = try await library.download(track)
                let file = try AVAudioFile(forReading: library.audioURL(for: downloaded.id))
                try engine.connectNode(player, to: timePitch, format: file.processingFormat)
                try engine.connectNode(timePitch, to: engine.mainMixerNode, format: file.processingFormat)
                audioFile = file
                track = downloaded
            }
            if position >= track.duration { position = 0 }
            try startPlayback()
        } catch {
            showPlaybackError(error)
        }
    }

    func seek(to seconds: TimeInterval) {
        guard track.duration > 0 else { return }
        let resume = isPlaying
        clearSchedule()
        position = min(max(0, seconds), track.duration)
        if resume, position < track.duration {
            do {
                try startPlayback()
            } catch {
                showPlaybackError(error)
            }
        } else {
            engine.pause()
            isPlaying = false
        }
    }

    private func applySettings() {
        timePitch.pitch = Float(settings.pitch * 100)
        timePitch.rate = Float(settings.tempo / 100)
    }

    private func startPlayback() throws {
        guard let file = audioFile else { return }
        if !engine.isRunning {
            let session = AVAudioSession.sharedInstance()
            if session.category != .playback {
                try session.setCategory(.playback)
            }
            try session.setActive(true)
            try engine.start()
        }
        if scheduledPlayback == nil {
            schedule(file)
        }
        try player.playAudio()
        isPlaying = true
    }

    private func schedule(_ file: AVAudioFile) {
        let sampleRate = file.processingFormat.sampleRate
        let startFrame = min(file.length - 1, AVAudioFramePosition(position * sampleRate))
        let count = AVAudioFrameCount(clamping: file.length - startFrame)
        let playback = UUID()
        segmentStart = Double(startFrame) / sampleRate
        scheduledPlayback = playback
        player.scheduleSegment(file, startingFrame: startFrame, frameCount: count, at: nil,
                               completionCallbackType: .dataPlayedBack) { @Sendable [weak self] _ in
            guard let self else { return }
            // Move off the audio callback before stopping or scheduling the node.
            Task { @MainActor in
                guard self.scheduledPlayback == playback else { return }
                self.stopPlayback()
                self.position = 0
            }
        }
    }

    private func clearSchedule() {
        scheduledPlayback = nil
        player.stop()
    }

    private func stopPlayback() {
        clearSchedule()
        engine.pause()
        isPlaying = false
    }

    private func showPlaybackError(_ error: Error) {
        stopPlayback()
        self.error = error.localizedDescription
    }
}
