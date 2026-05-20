import Foundation

/// Cursor debug-mode NDJSON log (session `594ccb`).
enum DebugSessionLog594ccb {
    static let sessionId = "594ccb"

    private static let logPath =
        "/Users/takcheung/Documents/Claude/Projects/Attention app/.cursor/debug-594ccb.log"

    private static var sharedLogPath: String {
        (BlockerSharedStateFile.sharedDirectoryPath as NSString)
            .appendingPathComponent("debug-594ccb.log")
    }

    private static var isNetworkExtensionProcess: Bool {
        Bundle.main.bundleIdentifier?
            .contains("network-extension") == true
    }

    private static var logPaths: [String] {
        if isNetworkExtensionProcess {
            return [
                logPath,
                sharedLogPath,
                BlockerDiagnosticsPaths.usersSharedExtensionMirrorURL.path,
            ]
        }
        return [logPath, sharedLogPath]
    }

    static func write(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: String] = [:],
        runId: String = "pre"
    ) {
        var enriched = data
        if isNetworkExtensionProcess {
            enriched["extBuild"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "missing"
        } else {
            enriched["extBuild"] = BlockerHostEnvironment.embeddedNetworkExtensionBuildVersion() ?? "missing"
        }
        let payload: [String: Any] = [
            "sessionId": sessionId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": enriched,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "runId": runId,
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let json = try? JSONSerialization.data(withJSONObject: payload),
              let line = String(data: json + Data([0x0a]), encoding: .utf8) else {
            return
        }
        for path in logPaths {
            appendLine(line, to: path)
        }
    }

    private static func appendLine(_ line: String, to path: String) {
        let url = URL(fileURLWithPath: path)
        let dir = url.deletingLastPathComponent()
        _ = try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { _ = try? handle.close() }
        _ = try? handle.seekToEnd()
        if let data = line.data(using: .utf8) {
            _ = try? handle.write(contentsOf: data)
        }
    }
}
