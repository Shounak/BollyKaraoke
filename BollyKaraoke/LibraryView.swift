import SwiftUI

struct LibraryView: View {
    let player: SongPlayer
    let play: (LibraryTrack) -> Void

    @State private var query = ""
    @ScaledMetric(relativeTo: .largeTitle) private var headingSize = 42

    private var searchText: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var matches: [LibraryTrack] {
        player.library.downloads.filter {
            searchText.isEmpty || $0.title.localizedStandardContains(searchText)
                || $0.subtitle.localizedStandardContains(searchText)
        }
    }

    private var featured: LibraryTrack {
        player.library.downloads.first { $0.id == LibraryTrack.sample.id } ?? .sample
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                searchField
                if searchText.isEmpty {
                    featuredCard
                }
                downloadList
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 9) {
                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(PracticeTheme.accent, in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)
                Text("BollyKaraoke")
                    .font(.subheadline.weight(.bold))
            }

            Text("Your library")
                .font(.system(size: headingSize, weight: .semibold, design: .serif))
                .tracking(-1.3)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var searchField: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(PracticeTheme.muted)
                .accessibilityHidden(true)
            TextField("Search your downloads", text: $query,
                      prompt: Text("Search your downloads").foregroundStyle(PracticeTheme.muted))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityIdentifier("library-search")
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(PracticeTheme.muted)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 15)
        .frame(minHeight: 52)
        .background(PracticeTheme.paper, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(PracticeTheme.line, lineWidth: 1)
        }
    }

    private var featuredCard: some View {
        Button {
            play(featured)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sample song")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PracticeTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(featured.title)
                        .font(.system(.title, design: .serif).weight(.semibold))
                        .lineLimit(2)
                    Text(featured.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(PracticeTheme.muted)
                        .lineLimit(2)
                }
                Label(featured.duration > 0 ? "Play sample" : "Download & play",
                      systemImage: featured.duration > 0 ? "play.fill" : "arrow.down")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .foregroundStyle(.white)
                    .background(PracticeTheme.accent, in: Capsule())
            }
            .frame(maxWidth: 215, alignment: .leading)
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 176, alignment: .leading)
            .background {
                RecordArtwork(center: 0.90)
                    .overlay {
                        LinearGradient(
                            stops: [.init(color: PracticeTheme.blush, location: 0),
                                    .init(color: PracticeTheme.blush, location: 0.44),
                                    .init(color: PracticeTheme.blush.opacity(0), location: 0.76)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .disabled(player.isLoading)
        .accessibilityIdentifier("featured-song")
    }

    private var downloadList: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(searchText.isEmpty ? "Downloads" : "Search results")
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(matches.count == 1 ? "1 song" : "\(matches.count) songs")
                    .font(.subheadline)
                    .foregroundStyle(PracticeTheme.muted)
            }

            if matches.isEmpty {
                Label(searchText.isEmpty ? "No downloads yet" : "No matching downloads",
                      systemImage: searchText.isEmpty ? "tray" : "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(PracticeTheme.muted)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PracticeTheme.paper, in: RoundedRectangle(cornerRadius: 18))
            } else {
                VStack(spacing: 0) {
                    ForEach(matches) { track in
                        downloadRow(track)
                        if track.id != matches.last?.id {
                            Rectangle()
                                .fill(PracticeTheme.line)
                                .frame(height: 1)
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(PracticeTheme.paper, in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private func downloadRow(_ track: LibraryTrack) -> some View {
        Button {
            play(track)
        } label: {
            HStack(spacing: 12) {
                RecordArtwork()
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Text(track.subtitle)
                        .font(.caption)
                        .foregroundStyle(PracticeTheme.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                if player.isPlaying, player.track.id == track.id {
                    Image(systemName: "waveform")
                        .foregroundStyle(PracticeTheme.accent)
                } else {
                    Text(trackTime(track.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PracticeTheme.muted)
                    Image(systemName: "play.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PracticeTheme.accent)
                }
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(player.isLoading)
        .accessibilityIdentifier("download-\(track.id)")
    }
}
