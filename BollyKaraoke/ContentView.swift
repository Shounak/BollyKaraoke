import SwiftUI

struct ContentView: View {
    @State private var output: String?

    var body: some View {
        VStack(spacing: 16) {
            Button("Check yt-dlp version", action: checkVersion)
                .buttonStyle(.borderedProminent)

            if let output {
                Text(output)
                    .monospaced()
                    .textSelection(.enabled)
                    .accessibilityIdentifier("yt-dlp-output")
            }
        }
        .padding()
    }

    private func checkVersion() {
        do {
            let version = try YTDLP.version()
            output = version
            print("yt-dlp \(version)")
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            output = message
            print(message)
        }
    }
}
