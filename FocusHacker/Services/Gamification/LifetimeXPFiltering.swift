import Foundation
import SwiftData

/// Lifetime XP totals ignore records before the most recent XP-only reset watermark.
@available(macOS 14.0, *)
enum LifetimeXPFiltering {
    static func countsTowardLifetimeXP(_ record: XPRecord, resetAt: Date?) -> Bool {
        guard let resetAt else { return true }
        return record.createdAt >= resetAt
    }

    static func shouldAwardLifetimeXP(forSessionEndedAt endedAt: Date, resetAt: Date?) -> Bool {
        guard let resetAt else { return true }
        return endedAt >= resetAt
    }

    static func sumLifetimeXP(from records: [XPRecord], resetAt: Date?) -> Int {
        records.reduce(0) { partial, record in
            guard countsTowardLifetimeXP(record, resetAt: resetAt) else { return partial }
            return partial + max(0, record.xpAmount)
        }
    }
}
