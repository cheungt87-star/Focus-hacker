import Foundation
import SwiftData

@available(macOS 14.0, *)
@Model
final class Session {
    var createdAt: Date
    var focusDurationMinutes: Int
    var roundsCompleted: Int
    var xpAwarded: Int
    var startedAt: Date?
    var endedAt: Date?
    var configuredRounds: Int?
    var didComplete: Bool?
    var totalFocusMinutes: Int?
    /// Correlates begin → complete / early end for one timer run (nil on legacy rows).
    var sessionUUID: UUID?
    /// True when session ended via full completion path (1.5× XP). Nil on legacy rows.
    var naturallyConcluded: Bool?

    @Relationship(deleteRule: .nullify, inverse: \XPRecord.session)
    var xpRecords: [XPRecord] = []

    init(
        createdAt: Date,
        focusDurationMinutes: Int,
        roundsCompleted: Int,
        xpAwarded: Int,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        configuredRounds: Int? = nil,
        didComplete: Bool? = nil,
        totalFocusMinutes: Int? = nil,
        sessionUUID: UUID? = nil,
        naturallyConcluded: Bool? = nil
    ) {
        self.createdAt = createdAt
        self.focusDurationMinutes = focusDurationMinutes
        self.roundsCompleted = roundsCompleted
        self.xpAwarded = xpAwarded
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.configuredRounds = configuredRounds
        self.didComplete = didComplete
        self.totalFocusMinutes = totalFocusMinutes
        self.sessionUUID = sessionUUID
        self.naturallyConcluded = naturallyConcluded
    }
}

@available(macOS 14.0, *)
@Model
final class XPRecord {
    var xpAmount: Int
    var createdAt: Date
    var focusMinutesContributing: Int?
    var naturallyConcluded: Bool?
    var session: Session?

    init(
        xpAmount: Int,
        createdAt: Date,
        focusMinutesContributing: Int? = nil,
        naturallyConcluded: Bool? = nil,
        session: Session? = nil
    ) {
        self.xpAmount = xpAmount
        self.createdAt = createdAt
        self.focusMinutesContributing = focusMinutesContributing
        self.naturallyConcluded = naturallyConcluded
        self.session = session
    }
}

@available(macOS 14.0, *)
@Model
final class StreakRecord {
    var streakValue: Int
    var evaluatedAt: Date
    var missedDaysBeforeEvaluation: Int

    init(streakValue: Int, evaluatedAt: Date, missedDaysBeforeEvaluation: Int) {
        self.streakValue = streakValue
        self.evaluatedAt = evaluatedAt
        self.missedDaysBeforeEvaluation = missedDaysBeforeEvaluation
    }
}

/// Single-row gamification progression (weekly targets, streaks, evaluation cursor).
@available(macOS 14.0, *)
@Model
final class PlayerProgress {
    /// Monday 00:00 (local) of the most recently **evaluated** closed week.
    var lastEvaluatedWeekStart: Date?
    /// Monday of the first week with any recorded focus activity.
    var firstActivityWeekStart: Date?
    var defaultTargetStreak: Int?
    var personalTargetStreak: Int?
    var longestDefaultTargetStreak: Int?
    var longestPersonalTargetStreak: Int?
    /// Personal weekly minutes target at last closed-week evaluation (detect target-change reset).
    var personalTargetMinutesAtLastEvaluation: Int?

    /// Legacy weekly XP level (v2); unused after gamification spec migration.
    var currentLevel: Int
    var lastWeekXPEarned: Int?

    init(
        lastEvaluatedWeekStart: Date? = nil,
        firstActivityWeekStart: Date? = nil,
        defaultTargetStreak: Int? = 0,
        personalTargetStreak: Int? = 0,
        longestDefaultTargetStreak: Int? = 0,
        longestPersonalTargetStreak: Int? = 0,
        personalTargetMinutesAtLastEvaluation: Int? = nil,
        currentLevel: Int = 1,
        lastWeekXPEarned: Int? = nil
    ) {
        self.lastEvaluatedWeekStart = lastEvaluatedWeekStart
        self.firstActivityWeekStart = firstActivityWeekStart
        self.defaultTargetStreak = defaultTargetStreak
        self.personalTargetStreak = personalTargetStreak
        self.longestDefaultTargetStreak = longestDefaultTargetStreak
        self.longestPersonalTargetStreak = longestPersonalTargetStreak
        self.personalTargetMinutesAtLastEvaluation = personalTargetMinutesAtLastEvaluation
        self.currentLevel = currentLevel
        self.lastWeekXPEarned = lastWeekXPEarned
    }
}
