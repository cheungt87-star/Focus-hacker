import Foundation
import SwiftData

protocol AnalyticsSessionReading: Sendable {
    func fetchEndedSessions() async throws -> [AnalyticsSessionRecord]
}

@available(macOS 14.0, *)
struct SwiftDataAnalyticsSessionReader: AnalyticsSessionReading, @unchecked Sendable {
    let container: ModelContainer

    func fetchEndedSessions() async throws -> [AnalyticsSessionRecord] {
        let context = ModelContext(container)
        let sessions = try context.fetch(FetchDescriptor<Session>())
        return sessions.compactMap { session -> AnalyticsSessionRecord? in
            guard let endedAt = session.endedAt else { return nil }
            let focusMinutes = GamificationSessionAggregation.focusMinutes(from: session)
            let natural = AnalyticsSessionStatusResolver.isNaturallyConcluded(
                naturallyConcluded: session.naturallyConcluded,
                didComplete: session.didComplete
            )
            let id = recordID(sessionUUID: session.sessionUUID, endedAt: endedAt)
            return AnalyticsSessionRecord(
                id: id,
                endedAt: endedAt,
                startedAt: session.startedAt,
                focusMinutes: focusMinutes,
                xpAwarded: max(0, session.xpAwarded),
                isNaturallyConcluded: natural
            )
        }
    }

    private func recordID(sessionUUID: UUID?, endedAt: Date) -> String {
        if let uuid = sessionUUID {
            return "\(uuid.uuidString)-\(endedAt.timeIntervalSince1970)"
        }
        return "legacy-\(endedAt.timeIntervalSince1970)"
    }
}

struct NoOpAnalyticsSessionReader: AnalyticsSessionReading {
    func fetchEndedSessions() async throws -> [AnalyticsSessionRecord] { [] }
}
