import Foundation
import SwiftData

enum FocusPlayerLevelTitle: Sendable {
    static func displayName(for level: Int) -> String {
        switch max(1, min(4, level)) {
        case 1: return "Novice"
        case 2: return "Rising"
        case 3: return "Focused"
        default: return "Master"
        }
    }
}

struct WeeklyLevelEvaluationOutcome: Sendable {
    let evaluatedAnyWeek: Bool
    let leveledUp: Bool
    let previousLevel: Int
    let newLevel: Int
}

protocol WeeklyLevelEvaluating: Sendable {
    func evaluatePendingClosedWeeks(now: Date) async throws -> WeeklyLevelEvaluationOutcome
    func currentPlayerLevel(now: Date) async throws -> Int
}

@available(macOS 14.0, *)
struct SwiftDataWeeklyLevelEvaluator: WeeklyLevelEvaluating, @unchecked Sendable {
    private let container: ModelContainer
    private let settingsStore: UserDefaultsSettingsStore

    init(container: ModelContainer, settingsStore: UserDefaultsSettingsStore) {
        self.container = container
        self.settingsStore = settingsStore
    }

    func currentPlayerLevel(now: Date) async throws -> Int {
        let context = ModelContext(container)
        let progress = try fetchOrInsertPlayerProgress(context: context)
        _ = try evaluatePendingClosedWeeksInternal(now: now, context: context, progress: progress)
        try context.save()
        return max(1, progress.currentLevel)
    }

    func evaluatePendingClosedWeeks(now: Date) async throws -> WeeklyLevelEvaluationOutcome {
        let context = ModelContext(container)
        let progress = try fetchOrInsertPlayerProgress(context: context)
        let outcome = try evaluatePendingClosedWeeksInternal(now: now, context: context, progress: progress)
        try context.save()
        return outcome
    }

    private func fetchOrInsertPlayerProgress(context: ModelContext) throws -> PlayerProgress {
        let descriptor = FetchDescriptor<PlayerProgress>()
        let rows = try context.fetch(descriptor)
        if let first = rows.first {
            return first
        }
        let created = PlayerProgress(currentLevel: 1, lastEvaluatedWeekStart: nil, lastWeekXPEarned: nil)
        context.insert(created)
        try context.save()
        return created
    }

    private func evaluatePendingClosedWeeksInternal(
        now: Date,
        context: ModelContext,
        progress: PlayerProgress
    ) throws -> WeeklyLevelEvaluationOutcome {
        let timeZone = TimeZone.current
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone

        let thisMonday = FocusCalendarWeekBounds.mondayStartOfWeek(containing: now, timeZone: timeZone)

        if progress.lastEvaluatedWeekStart == nil {
            progress.lastEvaluatedWeekStart = thisMonday
            return WeeklyLevelEvaluationOutcome(
                evaluatedAnyWeek: false,
                leveledUp: false,
                previousLevel: progress.currentLevel,
                newLevel: progress.currentLevel
            )
        }

        var cursor = progress.lastEvaluatedWeekStart ?? thisMonday
        let levelBeforeAllPasses = progress.currentLevel
        var anyEvaluatedWeek = false
        var anyLeveledUp = false

        while let weekEndExclusive = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor), now >= weekEndExclusive {
            anyEvaluatedWeek = true
            let xp = try xpSumExclusive(context: context, start: cursor, endExclusive: weekEndExclusive)
            let goal = settingsStore.weeklyXPGoalXP
            let oldLevel = progress.currentLevel
            if xp >= goal {
                progress.currentLevel = min(4, progress.currentLevel + 1)
            } else {
                progress.currentLevel = max(1, progress.currentLevel - 1)
            }
            if progress.currentLevel > oldLevel {
                anyLeveledUp = true
            }
            progress.lastWeekXPEarned = xp
            cursor = weekEndExclusive
            progress.lastEvaluatedWeekStart = cursor
        }

        return WeeklyLevelEvaluationOutcome(
            evaluatedAnyWeek: anyEvaluatedWeek,
            leveledUp: anyLeveledUp,
            previousLevel: levelBeforeAllPasses,
            newLevel: progress.currentLevel
        )
    }

    private func xpSumExclusive(context: ModelContext, start: Date, endExclusive: Date) throws -> Int {
        let descriptor = FetchDescriptor<XPRecord>()
        let records = try context.fetch(descriptor)
        return records.reduce(0) { partial, record in
            guard record.createdAt >= start, record.createdAt < endExclusive else { return partial }
            return partial + max(0, record.xpAmount)
        }
    }
}

struct NoOpWeeklyLevelEvaluator: WeeklyLevelEvaluating {
    func evaluatePendingClosedWeeks(now: Date) async throws -> WeeklyLevelEvaluationOutcome {
        WeeklyLevelEvaluationOutcome(evaluatedAnyWeek: false, leveledUp: false, previousLevel: 1, newLevel: 1)
    }

    func currentPlayerLevel(now: Date) async throws -> Int { 1 }
}
