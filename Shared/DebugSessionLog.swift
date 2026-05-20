import Foundation

/// Cursor debug-mode NDJSON log (session `aa87fc`).
enum DebugSessionLog {
    static let sessionId = "aa87fc"

    private static let logPath =
        "/Users/takcheung/Documents/Claude/Projects/Attention app/.cursor/debug-aa87fc.log"

    static func write(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: String] = [:],
        runId: String = "pre"
    ) {
        var enriched = data
        enriched["extBuild"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "missing"
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
        let url = URL(fileURLWithPath: logPath)
        if !FileManager.default.fileExists(atPath: logPath) {
            FileManager.default.createFile(atPath: logPath, contents: nil)
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { _ = try? handle.close() }
        _ = try? handle.seekToEnd()
        if let data = line.data(using: .utf8) {
            _ = try? handle.write(contentsOf: data)
        }
    }
}
