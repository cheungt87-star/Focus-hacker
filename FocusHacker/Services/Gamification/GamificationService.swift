import Foundation
import SwiftData

protocol XPStatsReading: Sendable {
    func totalAccumulatedXP() async throws -> Int
}

@available(macOS 14.0, *)
struct SwiftDataXPStatsReader: XPStatsReading, @unchecked Sendable {
    let container: ModelContainer

    func totalAccumulatedXP() async throws -> Int {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<XPRecord>()
        let records = try context.fetch(descriptor)
        return records.reduce(0) { $0 + max(0, $1.xpAmount) }
    }
}

struct NoOpXPStatsReader: XPStatsReading {
    func totalAccumulatedXP() async throws -> Int {
        0
    }
}
