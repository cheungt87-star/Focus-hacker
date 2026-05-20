import Foundation

enum FocusDayActivityState: String, Sendable {
    case completed
    case missed
    case future
}

struct FocusStreakSnapshot: Sendable, Equatable {
    let currentStreak: Int
    let bestStreak: Int
    /// Seven calendar days ending on `referenceNow`'s day (oldest → newest).
    let recentDayStates: [FocusDayActivityState]
}

enum FocusStreakCalculator {
    static let maxConsecutiveMissedDays = 2
    private static let recentDayCount = 7

    static func snapshot(
        activeDays: Set<Date>,
        referenceNow: Date,
        calendar: Calendar = .current
    ) -> FocusStreakSnapshot {
        let todayStart = calendar.startOfDay(for: referenceNow)
        let normalizedActive = Set(activeDays.map { calendar.startOfDay(for: $0) })

        return FocusStreakSnapshot(
            currentStreak: currentStreak(activeDays: normalizedActive, todayStart: todayStart, calendar: calendar),
            bestStreak: bestStreak(activeDays: normalizedActive, calendar: calendar),
            recentDayStates: recentDayStates(
                activeDays: normalizedActive,
                todayStart: todayStart,
                calendar: calendar
            )
        )
    }

    private static func currentStreak(
        activeDays: Set<Date>,
        todayStart: Date,
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var missed = 0
        var day = todayStart

        for _ in 0..<3_650 {
            if activeDays.contains(day) {
                streak += 1
                missed = 0
            } else {
                missed += 1
                if missed > maxConsecutiveMissedDays {
                    break
                }
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previous
        }

        return streak
    }

    private static func bestStreak(activeDays: Set<Date>, calendar: Calendar) -> Int {
        guard !activeDays.isEmpty else { return 0 }

        let sorted = activeDays.sorted()
        guard let earliest = sorted.first, let latest = sorted.last else { return 0 }

        var best = 0
        var streak = 0
        var missed = 0
        var day = earliest

        while day <= latest {
            if activeDays.contains(day) {
                streak += 1
                missed = 0
                best = max(best, streak)
            } else {
                missed += 1
                if missed > maxConsecutiveMissedDays {
                    streak = 0
                    missed = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else {
                break
            }
            day = next
        }

        return best
    }

    private static func recentDayStates(
        activeDays: Set<Date>,
        todayStart: Date,
        calendar: Calendar
    ) -> [FocusDayActivityState] {
        let offsets = Array((0..<recentDayCount).reversed())
        return offsets.map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayStart) else {
                return FocusDayActivityState.missed
            }
            if day > todayStart {
                return .future
            }
            return activeDays.contains(day) ? .completed : .missed
        }
    }
}
