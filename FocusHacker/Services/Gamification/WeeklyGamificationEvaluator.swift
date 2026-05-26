import Foundation
import SwiftData

struct WeeklyGamificationEvaluationOutcome: Sendable {
    let evaluatedAnyWeek: Bool
    let defaultTargetStreak: Int
    let personalTargetStreak: Int
    let longestDefaultTargetStreak: Int
    let longestPersonalTargetStreak: Int
}

protocol WeeklyGamificationEvaluating: Sendable {
    func evaluatePendingClosedWeeks(now: Date) async throws -> WeeklyGamificationEvaluationOutcome
    func cachedStreakSnapshot() async throws -> WeeklyGamificationEvaluationOutcome
}

@available(macOS 14.0, *)
struct SwiftDataWeeklyGamificationEvaluator: WeeklyGamificationEvaluating, @unchecked Sendable {
    private let container: ModelContainer
    private let settingsStore: UserDefaultsSettingsStore

    init(container: ModelContainer, settingsStore: UserDefaultsSettingsStore) {
        self.container = container
        self.settingsStore = settingsStore
    }

    func cachedStreakSnapshot() async throws -> WeeklyGamificationEvaluationOutcome {
        let context = ModelContext(container)
        let progress = try fetchOrInsertPlayerProgress(context: context)
        return snapshotOutcome(progress: progress, evaluatedAnyWeek: false)
    }

    func evaluatePendingClosedWeeks(now: Date) async throws -> WeeklyGamificationEvaluationOutcome {
        let context = ModelContext(container)
        let progress = try fetchOrInsertPlayerProgress(context: context)
        let outcome = try evaluatePendingClosedWeeksInternal(now: now, context: context, progress: progress)
        try context.save()
        return outcome
    }

    private func fetchOrInsertPlayerProgress(context: ModelContext) throws -> PlayerProgress {
        let descriptor = FetchDescriptor<PlayerProgress>()
        if let first = try context.fetch(descriptor).first {
            return first
        }
        let created = PlayerProgress()
        context.insert(created)
        try context.save()
        return created
    }

    private func evaluatePendingClosedWeeksInternal(
        now: Date,
        context: ModelContext,
        progress: PlayerProgress
    ) throws -> WeeklyGamificationEvaluationOutcome {
        let timeZone = TimeZone.current
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone

        let thisMonday = FocusCalendarWeekBounds.mondayStartOfWeek(containing: now, timeZone: timeZone)
        if progress.lastEvaluatedWeekStart == nil {
            progress.lastEvaluatedWeekStart = thisMonday
            try context.save()
            return snapshotOutcome(progress: progress, evaluatedAnyWeek: false)
        }

        let personalTarget = settingsStore.personalWeeklyMinutesTarget
        if progress.personalTargetMinutesAtLastEvaluation != personalTarget {
            progress.personalTargetStreak = 0
        }

        progress.defaultTargetStreak = progress.defaultTargetStreak ?? 0
        progress.personalTargetStreak = progress.personalTargetStreak ?? 0
        progress.longestDefaultTargetStreak = progress.longestDefaultTargetStreak ?? 0
        progress.longestPersonalTargetStreak = progress.longestPersonalTargetStreak ?? 0

        var cursor = progress.lastEvaluatedWeekStart ?? thisMonday
        var anyEvaluated = false

        while let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor), now >= weekEnd {
            anyEvaluated = true
            let minutes = try focusMinutesInWeek(context: context, start: cursor, endExclusive: weekEnd)

            if progress.firstActivityWeekStart == nil, minutes > 0 {
                progress.firstActivityWeekStart = cursor
            }

            let isFirstPartialWeek = progress.firstActivityWeekStart == cursor
            let proRataDays: Int? = isFirstPartialWeek
                ? proRataDaysForWeek(weekStart: cursor, endExclusive: weekEnd, context: context, calendar: calendar)
                : nil

            let evaluation = WeeklyTargetEvaluator.evaluate(
                WeeklyTargetEvaluationInput(
                    weekStart: cursor,
                    focusMinutes: minutes,
                    nominalDefaultTargetMinutes: WeeklyTargetEvaluator.defaultWeeklyMinutesTarget,
                    nominalPersonalTargetMinutes: personalTarget,
                    proRataDayCount: proRataDays,
                    isFirstPartialWeek: isFirstPartialWeek
                )
            )

            var defaultStreak = progress.defaultTargetStreak ?? 0
            var personalStreak = progress.personalTargetStreak ?? 0
            applyStreakHit(
                counts: evaluation.countsForDefaultStreak,
                isEvaluatedFullWeek: !isFirstPartialWeek,
                streak: &defaultStreak
            )
            applyStreakHit(
                counts: evaluation.countsForPersonalStreak,
                isEvaluatedFullWeek: !isFirstPartialWeek,
                streak: &personalStreak
            )
            progress.defaultTargetStreak = defaultStreak
            progress.personalTargetStreak = personalStreak

            progress.longestDefaultTargetStreak = max(progress.longestDefaultTargetStreak ?? 0, defaultStreak)
            progress.longestPersonalTargetStreak = max(progress.longestPersonalTargetStreak ?? 0, personalStreak)

            cursor = weekEnd
            progress.lastEvaluatedWeekStart = cursor
            progress.personalTargetMinutesAtLastEvaluation = personalTarget
        }

        return snapshotOutcome(progress: progress, evaluatedAnyWeek: anyEvaluated)
    }

    /// Increment streak on eligible hit; reset on full-week miss; no-op on pro-rata-only partial week.
    private func applyStreakHit(counts: Bool, isEvaluatedFullWeek: Bool, streak: inout Int) {
        if counts {
            streak += 1
        } else if isEvaluatedFullWeek {
            streak = 0
        }
    }

    private func snapshotOutcome(progress: PlayerProgress, evaluatedAnyWeek: Bool) -> WeeklyGamificationEvaluationOutcome {
        WeeklyGamificationEvaluationOutcome(
            evaluatedAnyWeek: evaluatedAnyWeek,
            defaultTargetStreak: progress.defaultTargetStreak ?? 0,
            personalTargetStreak: progress.personalTargetStreak ?? 0,
            longestDefaultTargetStreak: progress.longestDefaultTargetStreak ?? 0,
            longestPersonalTargetStreak: progress.longestPersonalTargetStreak ?? 0
        )
    }

    private func focusMinutesInWeek(context: ModelContext, start: Date, endExclusive: Date) throws -> Int {
        let sessions = try context.fetch(FetchDescriptor<Session>())
        return sessions.reduce(0) { partial, session in
            guard GamificationSessionAggregation.countsForWeeklyTarget(session),
                  let ended = session.endedAt,
                  ended >= start,
                  ended < endExclusive
            else {
                return partial
            }
            return partial + GamificationSessionAggregation.focusMinutes(from: session)
        }
    }

    private func proRataDaysForWeek(
        weekStart: Date,
        endExclusive: Date,
        context: ModelContext,
        calendar: Calendar
    ) -> Int? {
        guard let latest = latestSessionEndedAtInWeek(context: context, start: weekStart, endExclusive: endExclusive) else {
            return nil
        }
        return WeeklyTargetEvaluator.proRataDayCount(weekStart: weekStart, reference: latest, calendar: calendar)
    }

    private func latestSessionEndedAtInWeek(context: ModelContext, start: Date, endExclusive: Date) -> Date? {
        let sessions = try? context.fetch(FetchDescriptor<Session>())
        return sessions?
            .compactMap { session -> Date? in
                guard let ended = session.endedAt, ended >= start, ended < endExclusive, session.xpAwarded > 0 else {
                    return nil
                }
                return ended
            }
            .max()
    }
}

struct NoOpWeeklyGamificationEvaluator: WeeklyGamificationEvaluating {
    func evaluatePendingClosedWeeks(now: Date) async throws -> WeeklyGamificationEvaluationOutcome {
        WeeklyGamificationEvaluationOutcome(
            evaluatedAnyWeek: false,
            defaultTargetStreak: 0,
            personalTargetStreak: 0,
            longestDefaultTargetStreak: 0,
            longestPersonalTargetStreak: 0
        )
    }

    func cachedStreakSnapshot() async throws -> WeeklyGamificationEvaluationOutcome {
        try await evaluatePendingClosedWeeks(now: Date())
    }
}
