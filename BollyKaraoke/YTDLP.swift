import Foundation
import PythonKit

enum YTDLP {
    private static let worker = DispatchQueue(label: "com.shounak.BollyKaraoke.yt-dlp")
    private static let runtime: Result<Void, Error> = Result {
        let bundle = Bundle.main
        guard let resources = bundle.resourceURL,
              let frameworks = bundle.privateFrameworksURL,
              let wheel = bundle.url(forResource: "yt_dlp", withExtension: "whl"),
              let certificates = bundle.url(forResource: "certifi", withExtension: "whl") else {
            throw BridgeError.missingRuntime
        }

        let home = resources.appending(path: "python")
        guard FileManager.default.fileExists(atPath: home.path) else {
            throw BridgeError.missingRuntime
        }

        setenv("PYTHONHOME", home.path, 1)
        setenv("PYTHONPATH", [resources.path, wheel.path, certificates.path].joined(separator: ":"), 1)
        setenv("PYTHONDONTWRITEBYTECODE", "1", 1)
        setenv("PYTHONNOUSERSITE", "1", 1)
        PythonLibrary.useLibrary(at: frameworks.appending(path: "Python.framework/Python").path)
        try PythonLibrary.loadLibrary()

        // Initialize on the main thread and release the GIL for the downloader queue.
        _ = PythonKit.Python
        _ = PyEval_SaveThread()
    }

    static func downloadAudio(from url: URL, to file: URL) async throws {
        _ = try await call("download_audio", arguments: [url.absoluteString, file.path])
    }

    private static func call(_ name: String, arguments: [String]) async throws -> String {
        try runtime.get()

        return try await withCheckedThrowingContinuation { continuation in
            worker.async {
                let gil = PyGILState_Ensure()
                defer { PyGILState_Release(gil) }

                do {
                    continuation.resume(returning: try invoke(name, arguments: arguments))
                } catch PythonError.exception(let exception, _) {
                    // Convert Python objects before releasing the GIL.
                    continuation.resume(throwing: BridgeError.python(String(describing: exception)))
                } catch {
                    continuation.resume(throwing: BridgeError.python(String(describing: error)))
                }
            }
        }
    }

    private nonisolated static func invoke(_ name: String, arguments: [String]) throws -> String {
        let module = try PythonKit.Python.attemptImport("bollykaraoke_ytdlp")
        guard let function = module.checking[dynamicMember: name] else {
            throw BridgeError.unexpectedResult(name)
        }
        let result = try function.throwing.dynamicallyCall(withArguments: arguments.map { $0 as PythonConvertible })
        guard let value = String(result), !value.isEmpty else {
            throw BridgeError.unexpectedResult(name)
        }
        return value
    }

    private enum BridgeError: LocalizedError {
        case missingRuntime
        case unexpectedResult(String)
        case python(String)

        var errorDescription: String? {
            switch self {
            case .missingRuntime: "The bundled Python runtime or yt-dlp package is missing."
            case .unexpectedResult(let name): "The yt-dlp operation \(name) did not return a result."
            case .python(let message): message
            }
        }
    }
}
