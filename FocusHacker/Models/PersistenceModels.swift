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
        sessionUUID: UUID? = nil
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
    }
}

@available(macOS 14.0, *)
@Model
final class XPRecord {
    var xpAmount: Int
    var createdAt: Date
    var focusMinutesContributing: Int?
    var session: Session?

    init(
        xpAmount: Int,
        createdAt: Date,
        focusMinutesContributing: Int? = nil,
        session: Session? = nil
    ) {
        self.xpAmount = xpAmount
        self.createdAt = createdAt
        self.focusMinutesContributing = focusMinutesContributing
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

/// Single-row player progression (weekly goal level). Created on first access if missing.
@available(macOS 14.0, *)
@Model
final class PlayerProgress {
    var currentLevel: Int
    /// Monday 00:00 (local) of the most recently **evaluated** closed week (goal hit/miss applied).
    var lastEvaluatedWeekStart: Date?
    var lastWeekXPEarned: Int?

    init(currentLevel: Int = 1, lastEvaluatedWeekStart: Date? = nil, lastWeekXPEarned: Int? = nil) {
        self.currentLevel = currentLevel
        self.lastEvaluatedWeekStart = lastEvaluatedWeekStart
        self.lastWeekXPEarned = lastWeekXPEarned
    }
}
