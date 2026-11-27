import Foundation
import Observation
import YouTubeKit

struct YouTubeSong: Identifiable {
    let track: LibraryTrack
    let thumbnail: URL?
    let durationLabel: String?

    var id: String { track.id }

    init?(video: YTVideo) {
        guard LibraryTrack.isVideoID(video.videoId),
              let title = video.title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty,
              video.memberOnly != true,
              video.timeLength?.lowercased() != "live" else { return nil }

        track = LibraryTrack(id: video.videoId, title: title, subtitle: video.channel?.name ?? "YouTube",
                             duration: 0, downloadedAt: nil)
        let images = video.thumbnails.filter { $0.url.scheme == "https" }
            .sorted { ($0.width ?? 0) < ($1.width ?? 0) }
        thumbnail = (images.first { ($0.width ?? 0) >= 240 } ?? images.last)?.url
        durationLabel = video.timeLength
    }
}

@Observable
final class YouTubeSearch {
    var query = "" {
        didSet {
            if let submittedQuery, submittedQuery != searchText {
                resetResults()
            }
        }
    }

    private(set) var submittedQuery: String?
    private(set) var results: [YouTubeSong] = []
    private(set) var error: String?
    private(set) var isLoading = false

    private var nextPage: Cursor?
    @ObservationIgnored private var pendingRequest: Task<Void, Never>?
    @ObservationIgnored private let model: YouTubeModel = {
        let locale = Locale.current
        let language = locale.language.languageCode?.identifier ?? "en"
        let region = locale.region?.identifier ?? "US"
        let model = YouTubeModel()
        // YouTubeKit uses the language as the country unless both are specified.
        model.selectedLocale = "\(language)-\(region)"
        return model
    }()
    @ObservationIgnored private let session = URLSession(configuration: .ephemeral)

    private var searchText: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasMore: Bool { nextPage != nil }

    func submit() {
        guard !searchText.isEmpty else { return }
        resetResults()
        submittedQuery = searchText
        loadPage(after: nil)
    }

    func loadMore() {
        guard !isLoading, let nextPage else { return }
        loadPage(after: nextPage)
    }

    func retry() {
        guard !isLoading else { return }
        loadPage(after: nextPage)
    }

    private func resetResults() {
        pendingRequest?.cancel()
        pendingRequest = nil
        submittedQuery = nil
        results = []
        nextPage = nil
        error = nil
        isLoading = false
    }

    private func loadPage(after cursor: Cursor?) {
        guard let submittedQuery else { return }
        isLoading = true
        error = nil

        pendingRequest = Task { [weak self] in
            guard let self else { return }
            defer {
                if !Task.isCancelled {
                    self.isLoading = false
                    self.pendingRequest = nil
                }
            }

            do {
                let page = try await self.fetchPage(for: submittedQuery, after: cursor)
                try Task.checkCancellation()

                var seen = Set(self.results.map(\.id))
                self.results.append(contentsOf: page.songs.filter { seen.insert($0.id).inserted })
                self.nextPage = page.cursor?.token == cursor?.token ? nil : page.cursor
            } catch {
                guard !Task.isCancelled else { return }
                self.error = (error as? URLError)?.code == .notConnectedToInternet
                    ? "You’re offline. Connect to the internet to search YouTube."
                    : "YouTube search couldn’t load. Try again."
            }
        }
    }

    private func fetchPage(for query: String, after cursor: Cursor?) async throws -> Page {
        if let cursor {
            var parameters: YouTubeResponse.RequestData = [.continuation: cursor.token]
            if let visitorData = cursor.visitorData {
                parameters[.visitorData] = visitorData
            }
            let response = try await request(SearchResponse.Continuation.self, parameters: parameters)
            return Page(results: response.results, token: response.continuationToken, visitorData: cursor.visitorData)
        }

        // YouTubeKit inserts the query into a JSON string in its request template.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        let encodedQuery = try encoder.encode(query)
        let escapedQuery = String(decoding: encodedQuery.dropFirst().dropLast(), as: UTF8.self)
        let response = try await request(SearchResponse.self, parameters: [.query: escapedQuery])
        return Page(results: response.results, token: response.continuationToken, visitorData: response.visitorData)
    }

    private func request<Response: YouTubeResponse>(_ type: Response.Type,
                                                     parameters: YouTubeResponse.RequestData) async throws -> Response {
        let headers = model.getHeaders(forType: type.headersType)
        var request = HeadersList.setHeadersAgentFor(content: headers, data: parameters)
        request.httpShouldHandleCookies = false
        request.timeoutInterval = 20
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              http.mimeType == "application/json" else {
            throw URLError(.badServerResponse)
        }
        return try type.decodeData(data: data)
    }

    private struct Cursor {
        let token: String
        let visitorData: String?
    }

    private struct Page {
        let songs: [YouTubeSong]
        let cursor: Cursor?

        init(results: [any YTSearchResult], token: String?, visitorData: String?) {
            songs = results.compactMap { result in
                guard let video = result as? YTVideo else { return nil }
                return YouTubeSong(video: video)
            }
            cursor = token.flatMap { $0.isEmpty ? nil : Cursor(token: $0, visitorData: visitorData) }
        }
    }
}
