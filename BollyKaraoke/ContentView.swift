import SwiftUI

struct ContentView: View {
    let player: SongPlayer
    @State private var page = Page.library

    var body: some View {
        Group {
            switch page {
            case .library:
                LibraryView(player: player) { track in
                    player.select(track)
                    page = .player
                    if !player.isPlaying {
                        Task { await player.togglePlayback() }
                    }
                }
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
    }

    private enum Page: String {
        case library = "Library"
        case player = "Player"
    }
}
