import SwiftUI

@main
struct BollyKaraokeApp: App {
    @State private var player = SongPlayer(library: SongLibrary())

    var body: some Scene {
        WindowGroup {
            ContentView(player: player)
                .preferredColorScheme(.light)
        }
    }
}
