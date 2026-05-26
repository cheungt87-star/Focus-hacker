import Foundation

struct WeeklyStreakWeekInput: Sendable {
    let weekStart: Date
    let defaultTargetHit: Bool
    let personalTargetHit: Bool
}

struct WeeklyStreakSnapshot: Sendable, Equatable {
    let defaultStreak: Int
    let personalStreak: Int
    let longestDefaultStreak: Int
    let longestPersonalStreak: Int
}

enum WeeklyStreakCalculator {
    /// `closedWeeks` sorted ascending by `weekStart` (oldest first).
    static func snapshot(closedWeeks: [WeeklyStreakWeekInput]) -> WeeklyStreakSnapshot {
        let sorted = closedWeeks.sorted { $0.weekStart < $1.weekStart }
        return WeeklyStreakSnapshot(
            defaultStreak: currentStreak(sorted, keyPath: \.defaultTargetHit),
            personalStreak: currentStreak(sorted, keyPath: \.personalTargetHit),
            longestDefaultStreak: longestStreak(sorted, keyPath: \.defaultTargetHit),
            longestPersonalStreak: longestStreak(sorted, keyPath: \.personalTargetHit)
        )
    }

    private static func currentStreak(
        _ weeks: [WeeklyStreakWeekInput],
        keyPath: KeyPath<WeeklyStreakWeekInput, Bool>
    ) -> Int {
        var streak = 0
        for week in weeks.reversed() {
            if week[keyPath: keyPath] {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private static func longestStreak(
        _ weeks: [WeeklyStreakWeekInput],
        keyPath: KeyPath<WeeklyStreakWeekInput, Bool>
    ) -> Int {
        var best = 0
        var current = 0
        for week in weeks {
            if week[keyPath: keyPath] {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }
}
