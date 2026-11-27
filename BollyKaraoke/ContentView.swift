import SwiftUI

struct ContentView: View {
    let song: SampleSongPlayer

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Mere Khwabon Mein")
                    .font(.title2.weight(.semibold))
                Text("Dilwale Dulhania Le Jayenge")
                    .foregroundStyle(.secondary)
            }

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
