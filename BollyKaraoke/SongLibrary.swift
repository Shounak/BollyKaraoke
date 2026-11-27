import AVFAudio
import Foundation
import Observation

struct LibraryTrack: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let duration: TimeInterval
    let downloadedAt: Date?

    static let sample = LibraryTrack(
        id: "s1LozokQjIg",
        title: "Mere Khwabon Mein",
        subtitle: "Dilwale Dulhania Le Jayenge",
        duration: 0,
        downloadedAt: nil
    )

    static func isVideoID(_ id: String) -> Bool {
        id.range(of: #"^[A-Za-z0-9_-]{11}$"#, options: .regularExpression) != nil
    }
}

struct PracticeSettings: Codable, Equatable {
    var pitch = 0.0
    var tempo = 100.0
}

@Observable
final class SongLibrary {
    private(set) var downloads: [LibraryTrack] = []
    private(set) var downloadingID: String?
    @ObservationIgnored private let directory = URL.applicationSupportDirectory
        .appending(path: "Downloads", directoryHint: .isDirectory)
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var savedSettings: [String: PracticeSettings] = [:]

    init() {
        if let data = defaults.data(forKey: "practiceSettings"),
           let settings = try? JSONDecoder().decode([String: PracticeSettings].self, from: data) {
            savedSettings = settings
        }

        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        )) ?? []
        downloads = files.compactMap { file in
            guard file.pathExtension == "json",
                  let data = try? Data(contentsOf: file),
                  let track = try? JSONDecoder().decode(LibraryTrack.self, from: data),
                  LibraryTrack.isVideoID(track.id),
                  file.deletingPathExtension().lastPathComponent == track.id,
                  FileManager.default.fileExists(atPath: audioURL(for: track.id).path) else { return nil }
            return track
        }

        // Earlier versions saved the featured track without library metadata.
        let sample = LibraryTrack.sample
        let sampleURL = audioURL(for: sample.id)
        if !isDownloaded(sample.id),
           FileManager.default.fileExists(atPath: sampleURL.path),
           let file = try? AVAudioFile(forReading: sampleURL),
           file.length > 0 {
            downloads.append(LibraryTrack(
                id: sample.id, title: sample.title, subtitle: sample.subtitle,
                duration: Double(file.length) / file.processingFormat.sampleRate,
                downloadedAt: nil
            ))
        }
        downloads.sort { ($0.downloadedAt ?? .distantPast) > ($1.downloadedAt ?? .distantPast) }
    }

    func isDownloaded(_ id: String) -> Bool {
        downloadedTrack(id) != nil
    }

    func downloadedTrack(_ id: String) -> LibraryTrack? {
        downloads.first { $0.id == id }
    }

    func audioURL(for id: String) -> URL {
        directory.appending(path: "\(id).m4a")
    }

    func settings(for id: String) -> PracticeSettings {
        savedSettings[id] ?? PracticeSettings()
    }

    func save(_ settings: PracticeSettings, for id: String) {
        guard settings != self.settings(for: id) else { return }
        savedSettings[id] = settings
        if let data = try? JSONEncoder().encode(savedSettings) {
            defaults.set(data, forKey: "practiceSettings")
        }
    }

    func download(_ track: LibraryTrack) async throws -> LibraryTrack {
        let id = track.id
        guard LibraryTrack.isVideoID(id), let source = URL(string: "https://www.youtube.com/watch?v=\(id)") else {
            throw DownloadError.invalidTrack
        }
        let destination = audioURL(for: id)
        if let track = downloadedTrack(id),
           let file = try? AVAudioFile(forReading: destination), file.length > 0 {
            return track
        }
        guard downloadingID == nil else { throw DownloadError.alreadyDownloading }
        downloadingID = id
        defer { downloadingID = nil }

        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let staging = directory.appending(path: ".\(UUID().uuidString)", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? fileManager.removeItem(at: staging) }

        let incomingAudio = staging.appending(path: "audio.m4a")
        try await YTDLP.downloadAudio(from: source, to: incomingAudio)
        try Task.checkCancellation()
        let file = try AVAudioFile(forReading: incomingAudio)
        guard file.length > 0 else { throw DownloadError.emptyAudio }

        let savedTrack = LibraryTrack(
            id: id, title: track.title, subtitle: track.subtitle,
            duration: Double(file.length) / file.processingFormat.sampleRate,
            downloadedAt: .now
        )
        // A metadata entry is only loaded when its audio file exists.
        let metadataURL = directory.appending(path: "\(id).json")
        try JSONEncoder().encode(savedTrack).write(to: metadataURL, options: .atomic)
        if fileManager.fileExists(atPath: destination.path) {
            _ = try fileManager.replaceItemAt(destination, withItemAt: incomingAudio)
        } else {
            try fileManager.moveItem(at: incomingAudio, to: destination)
        }
        downloads.removeAll { $0.id == id }
        downloads.insert(savedTrack, at: 0)
        return savedTrack
    }

    private enum DownloadError: LocalizedError {
        case invalidTrack
        case alreadyDownloading
        case emptyAudio

        var errorDescription: String? {
            switch self {
            case .invalidTrack: "This song can’t be downloaded."
            case .alreadyDownloading: "Wait for the current download to finish."
            case .emptyAudio: "The download didn’t contain playable audio."
            }
        }
    }
}
