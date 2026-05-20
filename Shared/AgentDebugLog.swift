import Foundation

/// Session-scoped NDJSON debug log (host + system extension).
enum AgentDebugLog {
    static let sessionId = "fe1347"

    private static let workspaceLogPath =
        "/Users/takcheung/Documents/Claude/Projects/Attention app/.cursor/debug-fe1347.log"

    private static var sharedLogPath: String {
        (BlockerSharedStateFile.sharedDirectoryPath as NSString)
            .appendingPathComponent("debug-fe1347.log")
    }

    private static var isNetworkExtensionProcess: Bool {
        Bundle.main.bundleIdentifier?
            .contains("network-extension") == true
    }

    private static var logPaths: [String] {
        if isNetworkExtensionProcess {
            return [
                sharedLogPath,
                BlockerDiagnosticsPaths.usersSharedExtensionMirrorURL.path,
            ]
        }
        return [workspaceLogPath, sharedLogPath]
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
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: path) {
            guard FileManager.default.createFile(atPath: path, contents: nil) else { return }
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        if let data = line.data(using: .utf8) {
            try? handle.write(contentsOf: data)
        }
    }
}
