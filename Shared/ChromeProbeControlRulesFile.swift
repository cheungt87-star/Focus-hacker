import Foundation

/// Epoch-scoped probe IP rules pushed by the host for filter control / `applySettings` rematch (build 58).
enum ChromeProbeControlRulesFile {
    static let filename = "chrome-probe-control-rules.v1.json"

    struct Payload: Codable, Equatable {
        var blockingEpoch: String
        var probeIPs: [String]
        var rulesGeneration: UInt64
        var lastUpdatedAtReference: Double = 0
    }

    private static let stateQueue = DispatchQueue(label: "com.focushacker.blocker.chrome-probe-control-rules")

    private static func fileURL() -> URL {
        URL(fileURLWithPath: BlockerSharedStateFile.sharedDirectoryPath, isDirectory: true)
            .appendingPathComponent(filename, isDirectory: false)
    }

    static func read() -> Payload? {
        stateQueue.sync { readUnlocked() }
    }

    private static func readUnlocked() -> Payload? {
        let url = fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(Payload.self, from: data)
    }

    static func write(_ payload: Payload) {
        stateQueue.sync {
            writeUnlocked(payload)
        }
    }

    private static func writeUnlocked(_ payload: Payload) {
        let url = fileURL()
        var stamped = payload
        stamped.lastUpdatedAtReference = Date().timeIntervalSinceReferenceDate
        let directory = url.deletingLastPathComponent()
        let tmp = directory.appendingPathComponent("\(filename).tmp", isDirectory: false)
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o777]
            )
            let data = try JSONEncoder().encode(stamped)
            try data.write(to: tmp, options: [.atomic])
            if FileManager.default.fileExists(atPath: url.path) {
                _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
            } else {
                try FileManager.default.moveItem(at: tmp, to: url)
            }
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
        } catch {
            try? FileManager.default.removeItem(at: tmp)
        }
    }

    /// Monotonic generation for host pushes (read-modify-write under queue).
    static func nextRulesGeneration() -> UInt64 {
        stateQueue.sync {
            let current = readUnlocked()?.rulesGeneration ?? 0
            return current + 1
        }
    }

    static func buildPayload(blockingEpoch: String, probeIPs: [String]) -> Payload {
        let canonical = probeIPs.compactMap { BlockerIPLiteralCanonical.canonical($0) }
        return Payload(
            blockingEpoch: blockingEpoch,
            probeIPs: Array(Set(canonical)).sorted(),
            rulesGeneration: nextRulesGeneration()
        )
    }
}
