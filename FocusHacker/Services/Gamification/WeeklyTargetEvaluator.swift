import Foundation

struct WeeklyTargetEvaluationInput: Sendable {
    let weekStart: Date
    let focusMinutes: Int
    let nominalDefaultTargetMinutes: Int
    let nominalPersonalTargetMinutes: Int?
    /// When set, pro-rata applies to this week only (first partial week).
    let proRataDayCount: Int?
    let isFirstPartialWeek: Bool
}

struct WeeklyTargetEvaluationResult: Sendable {
    let effectiveDefaultTargetMinutes: Int
    let effectivePersonalTargetMinutes: Int?
    let defaultTargetHit: Bool
    let personalTargetHit: Bool
    /// Streak credit applies only when not a pro-rata partial week (spec §6.3).
    let countsForDefaultStreak: Bool
    let countsForPersonalStreak: Bool
}

enum WeeklyTargetEvaluator {
    static let defaultWeeklyMinutesTarget = 800

    static func effectiveTargetMinutes(
        nominalTarget: Int,
        proRataDayCount: Int?,
        isFirstPartialWeek: Bool
    ) -> Int {
        let nominal = max(1, nominalTarget)
        guard isFirstPartialWeek, let days = proRataDayCount, days > 0, days < 7 else {
            return nominal
        }
        let scaled = (Double(nominal) * Double(days) / 7.0).rounded(.up)
        return max(1, Int(scaled))
    }

    static func evaluate(_ input: WeeklyTargetEvaluationInput) -> WeeklyTargetEvaluationResult {
        let minutes = max(0, input.focusMinutes)
        let effectiveDefault = effectiveTargetMinutes(
            nominalTarget: input.nominalDefaultTargetMinutes,
            proRataDayCount: input.proRataDayCount,
            isFirstPartialWeek: input.isFirstPartialWeek
        )
        let effectivePersonal: Int? = input.nominalPersonalTargetMinutes.map { nominal in
            effectiveTargetMinutes(
                nominalTarget: nominal,
                proRataDayCount: input.proRataDayCount,
                isFirstPartialWeek: input.isFirstPartialWeek
            )
        }

        let defaultHit = minutes >= effectiveDefault
        let personalHit = effectivePersonal.map { minutes >= $0 } ?? false
        let streakEligible = !input.isFirstPartialWeek || input.proRataDayCount == nil

        return WeeklyTargetEvaluationResult(
            effectiveDefaultTargetMinutes: effectiveDefault,
            effectivePersonalTargetMinutes: effectivePersonal,
            defaultTargetHit: defaultHit,
            personalTargetHit: personalHit,
            countsForDefaultStreak: streakEligible && defaultHit,
            countsForPersonalStreak: streakEligible && personalHit
        )
    }

    /// Days from `weekStart` through `reference` (inclusive), capped at 7.
    static func proRataDayCount(
        weekStart: Date,
        reference: Date,
        calendar: Calendar
    ) -> Int {
        let start = calendar.startOfDay(for: weekStart)
        let end = calendar.startOfDay(for: reference)
        guard end >= start else { return 0 }
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return min(7, max(1, days + 1))
    }
}
