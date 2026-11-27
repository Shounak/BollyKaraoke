import Foundation
import PythonKit

enum YTDLP {
    private static let runtime: Result<Void, Error> = Result {
        let bundle = Bundle.main
        guard let resources = bundle.resourceURL,
              let frameworks = bundle.privateFrameworksURL,
              let wheel = bundle.url(forResource: "yt_dlp", withExtension: "whl") else {
            throw VersionError.missingRuntime
        }

        let home = resources.appending(path: "python")
        guard FileManager.default.fileExists(atPath: home.path) else {
            throw VersionError.missingRuntime
        }

        // PythonKit initializes CPython on first use, so configure its bundle paths first.
        setenv("PYTHONHOME", home.path, 1)
        setenv("PYTHONPATH", [resources.path, wheel.path].joined(separator: ":"), 1)
        setenv("PYTHONDONTWRITEBYTECODE", "1", 1)
        setenv("PYTHONNOUSERSITE", "1", 1)
        PythonLibrary.useLibrary(at: frameworks.appending(path: "Python.framework/Python").path)
        try PythonLibrary.loadLibrary()
    }

    static func version() throws -> String {
        try runtime.get()
        let module = try Python.attemptImport("bollykaraoke_ytdlp")
        let result = try module.check_version.throwing.dynamicallyCall(withArguments: [])
        guard let version = String(result), !version.isEmpty else {
            throw VersionError.missingVersion
        }
        return version
    }

    private enum VersionError: LocalizedError {
        case missingRuntime
        case missingVersion

        var errorDescription: String? {
            switch self {
            case .missingRuntime: "The bundled Python runtime or yt-dlp package is missing."
            case .missingVersion: "yt-dlp did not print a version."
            }
        }
    }
}
