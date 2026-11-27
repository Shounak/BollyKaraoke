import SwiftUI

struct YouTubeSearchView: View {
    @Bindable var search: YouTubeSearch
    let player: SongPlayer
    let play: (LibraryTrack) -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var headingSize = 42

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 15) {
                Text("Search YouTube")
                    .font(.system(size: headingSize, weight: .semibold, design: .serif))
                    .tracking(-1.3)
                    .accessibilityAddTraits(.isHeader)

                SongSearchField(title: "Song, film, or artist", identifier: "youtube-search", text: $search.query,
                                onSearch: search.submit)

                if search.submittedQuery != nil {
                    results
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var results: some View {
        Section {
            ForEach(search.results) { song in
                resultRow(song)
            }

            if search.isLoading {
                ProgressView(search.results.isEmpty ? "Searching YouTube…" : "Loading more…")
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            } else if let error = search.error {
                VStack(alignment: .leading, spacing: 8) {
                    Label(error, systemImage: "exclamationmark.circle")
                        .foregroundStyle(PracticeTheme.muted)
                        .accessibilityIdentifier("youtube-search-error")
                    Button("Try again", action: search.retry)
                        .buttonStyle(.bordered)
                }
            } else {
                if search.results.isEmpty {
                    Text("No videos found.")
                        .foregroundStyle(PracticeTheme.muted)
                }
                if search.hasMore {
                    Button("Load more results", action: search.loadMore)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("youtube-load-more")
                }
            }
        } header: {
            HStack {
                Text("YouTube results")
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !search.results.isEmpty {
                    Text(search.results.count == 1 ? "1 video" : "\(search.results.count) videos")
                        .font(.subheadline)
                        .foregroundStyle(PracticeTheme.muted)
                        .accessibilityIdentifier("youtube-result-count")
                }
            }
        }
    }

    private func resultRow(_ song: YouTubeSong) -> some View {
        let isDownloaded = player.library.isDownloaded(song.id)
        return Button {
            play(song.track)
        } label: {
            HStack(spacing: 12) {
                AsyncImage(url: song.thumbnail) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RecordArtwork()
                }
                .frame(width: 96, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(song.track.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Text([song.track.subtitle, song.durationLabel].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(PracticeTheme.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Image(systemName: isDownloaded ? "play.fill" : "arrow.down.circle")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PracticeTheme.accent)
                    .frame(width: 25)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .background(PracticeTheme.paper, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(player.isLoading)
        .accessibilityHint(isDownloaded ? "Play downloaded audio" : "Download audio and play")
        .accessibilityIdentifier("youtube-result-\(song.id)")
    }
}
