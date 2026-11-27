import SwiftUI

struct PlayerView: View {
    @Bindable var player: SongPlayer
    @State private var scrubPosition: TimeInterval?

    private var pitchValue: String {
        let semitones = Int(player.settings.pitch)
        let signedValue = semitones.formatted(.number.sign(strategy: .always(includingZero: false)))
        return "\(signedValue) \(abs(semitones) == 1 ? "semitone" : "semitones")"
    }

    private var tempoValue: String {
        (player.settings.tempo / 100).formatted(.percent.precision(.fractionLength(0)))
    }

    private var isDownloaded: Bool { player.library.isDownloaded(player.track.id) }
    private var canSeek: Bool { player.track.duration > 0 && !player.isLoading }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heading
                RecordArtwork()
                    .frame(height: 158)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                songTitle
                transport
                if let error = player.error {
                    Label(error, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(PracticeTheme.accent)
                        .accessibilityIdentifier("sample-song-error")
                }
                settings
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .frame(maxWidth: 550)
            .frame(maxWidth: .infinity)
        }
        .onChange(of: player.track.id) { scrubPosition = nil }
    }

    private var heading: some View {
        HStack {
            Text("Player")
                .font(.system(.title2, design: .serif).weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if isDownloaded {
                Label("Downloaded", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PracticeTheme.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(PracticeTheme.green.opacity(0.09), in: Capsule())
            }
        }
    }

    private var songTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(player.track.title)
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .tracking(-0.8)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("player-song-title")
            Text(player.track.subtitle)
                .font(.subheadline)
                .foregroundStyle(PracticeTheme.muted)
        }
    }

    private var transport: some View {
        VStack(spacing: 8) {
            if player.isPlaying {
                TimelineView(.animation(minimumInterval: 0.15)) { _ in
                    timeline(at: player.currentTime)
                }
            } else {
                timeline(at: player.currentTime)
            }

            HStack(spacing: 28) {
                skipButton(by: -10, icon: "gobackward.10", title: "Back 10 seconds")
                playButton
                skipButton(by: 10, icon: "goforward.10", title: "Forward 10 seconds")
            }
            .frame(maxWidth: .infinity)

            if player.isLoading || !isDownloaded {
                Text(player.isLoading ? "Downloading…" : "Download & play")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PracticeTheme.muted)
                    .accessibilityHidden(true)
            }
        }
    }

    private func timeline(at currentTime: TimeInterval) -> some View {
        let position = scrubPosition ?? currentTime
        return VStack(spacing: 2) {
            Slider(
                value: Binding(get: { position }, set: updatePosition),
                in: 0...max(player.track.duration, 1),
                onEditingChanged: scrub
            )
            .disabled(!canSeek)
            .accessibilityLabel("Playback position")
            .accessibilityValue("\(trackTime(position)) of \(trackTime(player.track.duration))")
            .accessibilityIdentifier("playback-position")

            HStack {
                Text(trackTime(position))
                Spacer()
                Text(trackTime(player.track.duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(PracticeTheme.muted)
            .accessibilityHidden(true)
        }
    }

    private var playButton: some View {
        Button {
            scrubPosition = nil
            Task { await player.togglePlayback() }
        } label: {
            Group {
                if player.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: player.isPlaying ? "pause.fill" : (isDownloaded ? "play.fill" : "arrow.down"))
                        .font(.system(size: 24, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(PracticeTheme.accent, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(player.isLoading)
        .accessibilityLabel(player.isLoading ? "Downloading" : (player.isPlaying ? "Pause" : (isDownloaded ? "Play" : "Download and Play")))
        .accessibilityIdentifier("sample-song-playback")
    }

    private func skipButton(by offset: TimeInterval, icon: String, title: String) -> some View {
        Button {
            scrubPosition = nil
            player.seek(to: player.currentTime + offset)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(PracticeTheme.ink)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canSeek)
        .opacity(canSeek ? 1 : 0.4)
        .accessibilityLabel(title)
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Practice settings")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if player.settings != PracticeSettings() {
                    Button("Reset") { player.settings = PracticeSettings() }
                        .font(.subheadline.weight(.semibold))
                        .tint(PracticeTheme.accent)
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Reset practice settings")
                }
            }

            PracticeSlider(title: "Pitch", icon: "music.note", reading: pitchValue, range: -6...6,
                           identifier: "sample-song-pitch", value: $player.settings.pitch)
            Divider().overlay(PracticeTheme.line)
            PracticeSlider(title: "Tempo", icon: "metronome", reading: tempoValue, range: 75...125,
                           identifier: "sample-song-tempo", value: $player.settings.tempo)
        }
        .padding(16)
        .background(PracticeTheme.paper, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22).strokeBorder(PracticeTheme.line, lineWidth: 1)
        }
    }

    private func updatePosition(_ seconds: TimeInterval) {
        if scrubPosition != nil {
            scrubPosition = seconds
        } else {
            player.seek(to: seconds)
        }
    }

    private func scrub(_ editing: Bool) {
        if editing {
            scrubPosition = player.currentTime
        } else if let position = scrubPosition {
            scrubPosition = nil
            player.seek(to: position)
        }
    }
}

private struct PracticeSlider: View {
    let title: String
    let icon: String
    let reading: String
    let range: ClosedRange<Double>
    let identifier: String
    @Binding var value: Double

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(PracticeTheme.accent)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(reading)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(PracticeTheme.muted)
            }
            .accessibilityHidden(true)

            Slider(value: $value, in: range, step: 1)
                .accessibilityLabel(title)
                .accessibilityValue(reading)
                .accessibilityIdentifier(identifier)
        }
    }
}
