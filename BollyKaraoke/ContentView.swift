import SwiftUI

struct ContentView: View {
    let player: SongPlayer
    @State private var page = Page.library
    @State private var search = YouTubeSearch()

    var body: some View {
        Group {
            switch page {
            case .library:
                LibraryView(player: player, play: play)
            case .search:
                YouTubeSearchView(search: search, player: player, play: play)
            case .player:
                PlayerView(player: player)
            }
        }
        .foregroundStyle(PracticeTheme.ink)
        .tint(PracticeTheme.accent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PracticeTheme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 10) {
                tab(.library, icon: "square.stack")
                tab(.search, icon: "magnifyingglass")
                tab(.player, icon: "waveform")
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(PracticeTheme.paper.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) {
                Rectangle().fill(PracticeTheme.line).frame(height: 1)
            }
        }
    }

    private func play(_ track: LibraryTrack) {
        guard !player.isLoading else { return }
        player.select(player.library.downloadedTrack(track.id) ?? track)
        page = .player
        if !player.isPlaying {
            Task { await player.togglePlayback() }
        }
    }

    private func tab(_ tab: Page, icon: String) -> some View {
        Button {
            page = tab
        } label: {
            Label(tab.rawValue, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(page == tab ? PracticeTheme.accent : PracticeTheme.muted)
                .background(page == tab ? PracticeTheme.blush : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(page == tab ? .isSelected : [])
        .accessibilityIdentifier("\(tab.rawValue.lowercased())-tab")
    }

    private enum Page: String {
        case library = "Library"
        case search = "Search"
        case player = "Player"
    }
}
