import Foundation

enum PersonalWeeklyTargetFormatting {
    static let minutesStep = 5

    static func split(totalMinutes: Int) -> (hours: Int, minutes: Int) {
        let bounded = max(0, totalMinutes)
        return (bounded / 60, bounded % 60)
    }

    static func compose(hours: Int, minutes: Int) -> Int {
        max(0, hours) * 60 + max(0, minutes)
    }

    static func clampedTotalMinutes(hours: Int, minutes: Int) -> Int {
        UserDefaultsSettingsStore.clampPersonalWeeklyMinutes(
            compose(hours: hours, minutes: minutes)
        )
    }

    /// Clamps composed total, then returns display parts matching stored minutes.
    static func normalizedParts(hours: Int, minutes: Int) -> (hours: Int, minutes: Int, totalMinutes: Int) {
        let total = clampedTotalMinutes(hours: hours, minutes: minutes)
        let parts = split(totalMinutes: total)
        return (parts.hours, parts.minutes, total)
    }

    static func snappedMinutesComponent(_ minutes: Int) -> Int {
        min(55, max(0, (minutes / minutesStep) * minutesStep))
    }

    /// Editor opens from the hacker goal (800 min → 13 h, 20 m).
    static func editorBaselineParts() -> (hours: Int, minutes: Int) {
        let parts = split(totalMinutes: ProfileDashboardMetrics.defaultWeeklyMinutesTarget)
        return (parts.hours, snappedMinutesComponent(parts.minutes))
    }

    static func incrementHours(hours: inout Int, minutes: inout Int) {
        hours += 1
    }

    static func decrementHours(hours: inout Int, minutes: inout Int) {
        hours -= 1
    }

    static func incrementMinutes(hours: inout Int, minutes: inout Int) {
        if minutes >= 55 {
            minutes = 0
            hours += 1
        } else {
            minutes += minutesStep
        }
    }

    static func decrementMinutes(hours: inout Int, minutes: inout Int) {
        if minutes <= 0 {
            minutes = 55
            hours -= 1
        } else {
            minutes -= minutesStep
        }
    }

    static func canIncrementHours(hours: Int, minutes: Int) -> Bool {
        let current = clampedTotalMinutes(hours: hours, minutes: minutes)
        var draftHours = hours
        var draftMinutes = minutes
        incrementHours(hours: &draftHours, minutes: &draftMinutes)
        return clampedTotalMinutes(hours: draftHours, minutes: draftMinutes) > current
    }

    static func canDecrementHours(hours: Int, minutes: Int) -> Bool {
        let current = clampedTotalMinutes(hours: hours, minutes: minutes)
        var draftHours = hours
        var draftMinutes = minutes
        decrementHours(hours: &draftHours, minutes: &draftMinutes)
        return clampedTotalMinutes(hours: draftHours, minutes: draftMinutes) < current
    }

    static func canIncrementMinutes(hours: Int, minutes: Int) -> Bool {
        let current = clampedTotalMinutes(hours: hours, minutes: minutes)
        var draftHours = hours
        var draftMinutes = minutes
        incrementMinutes(hours: &draftHours, minutes: &draftMinutes)
        return clampedTotalMinutes(hours: draftHours, minutes: draftMinutes) > current
    }

    static func canDecrementMinutes(hours: Int, minutes: Int) -> Bool {
        let current = clampedTotalMinutes(hours: hours, minutes: minutes)
        var draftHours = hours
        var draftMinutes = minutes
        decrementMinutes(hours: &draftHours, minutes: &draftMinutes)
        return clampedTotalMinutes(hours: draftHours, minutes: draftMinutes) < current
    }

    static func accessibilityLabel(hours: Int, minutes: Int, totalMinutes: Int) -> String {
        "\(hours) hours \(minutes) minutes per week (\(totalMinutes) minutes)"
    }

    static func settingsAccessibilityLabel(totalMinutes: Int) -> String {
        "\(totalMinutes) minutes per week"
    }

    // MARK: - Hacker goal comparison

    static func deltaVersusHackerGoalMinutes(
        personalMinutes: Int,
        hackerGoalMinutes: Int = ProfileDashboardMetrics.defaultWeeklyMinutesTarget
    ) -> Int {
        personalMinutes - hackerGoalMinutes
    }

    static func percentVersusHackerGoal(
        personalMinutes: Int,
        hackerGoalMinutes: Int = ProfileDashboardMetrics.defaultWeeklyMinutesTarget
    ) -> Int {
        guard hackerGoalMinutes > 0 else { return 0 }
        return Int((Double(personalMinutes) / Double(hackerGoalMinutes) * 100).rounded())
    }

    static func deltaVersusHackerGoalDisplay(deltaMinutes: Int) -> String {
        if deltaMinutes > 0 {
            return "+\(deltaMinutes) min"
        }
        if deltaMinutes < 0 {
            return "\(deltaMinutes) min"
        }
        return "0 min"
    }

    static func percentVersusHackerGoalDisplay(percent: Int) -> String {
        "\(percent)% of hacker goal"
    }

    static func hackerGoalComparisonAccessibilityLabel(deltaMinutes: Int, percent: Int) -> String {
        let deltaPhrase: String
        if deltaMinutes > 0 {
            deltaPhrase = "\(deltaMinutes) minutes above hacker goal"
        } else if deltaMinutes < 0 {
            deltaPhrase = "\(abs(deltaMinutes)) minutes below hacker goal"
        } else {
            deltaPhrase = "same as hacker goal"
        }
        return "\(deltaPhrase), \(percent) percent of hacker goal"
    }
}
