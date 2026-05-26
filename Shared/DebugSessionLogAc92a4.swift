import Foundation

/// Cursor debug-mode NDJSON log (session `ac92a4`).
enum DebugSessionLogAc92a4 {
    static let sessionId = "ac92a4"

    private static let logPath =
        "/Users/takcheung/Documents/Claude/Projects/Attention app/.cursor/debug-ac92a4.log"

    static func write(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: String] = [:],
        runId: String = "pre"
    ) {
        let payload: [String: Any] = [
            "sessionId": sessionId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
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
        defer { try? handle.close() }
        try? handle.seekToEnd()
        if let data = line.data(using: .utf8) {
            try? handle.write(contentsOf: data)
        }
    }
}
