import Foundation
import SwiftData

/// One-time recomputation of XP amounts for legacy sessions (2× minutes → spec formula).
@available(macOS 14.0, *)
enum GamificationXPBackfill {
    static func runIfNeeded(container: ModelContainer, settingsStore: UserDefaultsSettingsStore) throws {
        guard !settingsStore.gamificationXPBackfillCompleted else { return }
        let context = ModelContext(container)
        let resetAt = settingsStore.lifetimeXPResetAt
        let records = try context.fetch(FetchDescriptor<XPRecord>())
        for record in records {
            guard let session = record.session else { continue }
            let sessionEndedAt = session.endedAt ?? session.createdAt
            guard LifetimeXPFiltering.shouldAwardLifetimeXP(forSessionEndedAt: sessionEndedAt, resetAt: resetAt) else {
                continue
            }
            let minutes = max(0, session.totalFocusMinutes ?? session.focusDurationMinutes)
            let natural = session.naturallyConcluded ?? (session.didComplete == true)
            let xp = FocusXPCalculator.xp(forFocusMinutes: minutes, naturallyConcluded: natural)
            record.xpAmount = xp
            record.focusMinutesContributing = minutes
            record.naturallyConcluded = natural
            session.xpAwarded = xp
            session.naturallyConcluded = natural
        }
        let earlySessions = try context.fetch(FetchDescriptor<Session>())
        for session in earlySessions where session.xpAwarded == 0 {
            let minutes = max(0, session.totalFocusMinutes ?? session.focusDurationMinutes)
            guard minutes > 0, let endedAt = session.endedAt else { continue }
            guard LifetimeXPFiltering.shouldAwardLifetimeXP(forSessionEndedAt: endedAt, resetAt: resetAt) else {
                continue
            }
            let natural = session.naturallyConcluded ?? false
            let xp = FocusXPCalculator.xp(forFocusMinutes: minutes, naturallyConcluded: natural)
            guard xp > 0 else { continue }
            session.xpAwarded = xp
            session.naturallyConcluded = natural
            if session.xpRecords.isEmpty {
                let xpRecord = XPRecord(
                    xpAmount: xp,
                    createdAt: session.endedAt ?? session.createdAt,
                    focusMinutesContributing: minutes,
                    naturallyConcluded: natural,
                    session: session
                )
                context.insert(xpRecord)
            }
        }
        try context.save()
        settingsStore.gamificationXPBackfillCompleted = true
    }
}
