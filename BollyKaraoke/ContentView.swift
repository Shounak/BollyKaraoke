import SwiftUI

struct ContentView: View {
    @Bindable var song: SampleSongPlayer

    private var pitchValue: String {
        let semitones = Int(song.pitchSemitones)
        let signedValue = semitones.formatted(.number.sign(strategy: .always(includingZero: false)))
        return "\(signedValue) \(abs(semitones) == 1 ? "semitone" : "semitones")"
    }

    private var tempoValue: String {
        (song.tempoPercent / 100).formatted(.percent.precision(.fractionLength(0)))
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Mere Khwabon Mein")
                    .font(.title2.weight(.semibold))
                Text("Dilwale Dulhania Le Jayenge")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Pitch")
                        Spacer()
                        Text(pitchValue)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .accessibilityHidden(true)

                    Slider(value: $song.pitchSemitones, in: -6...6, step: 1)
                        .accessibilityLabel("Pitch")
                        .accessibilityValue(pitchValue)
                        .accessibilityIdentifier("sample-song-pitch")
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Tempo")
                        Spacer()
                        Text(tempoValue)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .accessibilityHidden(true)

                    Slider(value: $song.tempoPercent, in: 75...125, step: 1)
                        .accessibilityLabel("Tempo")
                        .accessibilityValue(tempoValue)
                        .accessibilityIdentifier("sample-song-tempo")
                }
            }
            .frame(maxWidth: 400)

            Button(song.buttonTitle) {
                Task { await song.togglePlayback() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(song.isLoading)
            .accessibilityIdentifier("sample-song-playback")

            if let error = song.error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("sample-song-error")
            }
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}
