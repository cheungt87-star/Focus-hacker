import Foundation

/// UI chart period for the profile dashboard (maps to `StatsDashboardWindow` for data fetch).
enum ProfileChartPeriod: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case year

    /// Periods exposed in the profile chart header toggle (W, M, Y).
    static let chartToggleCases: [ProfileChartPeriod] = [.week, .month, .year]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }

    /// Compact label for the profile chart period toggle (W, M, Y).
    var shortTitle: String {
        switch self {
        case .week: return "W"
        case .month: return "M"
        case .year: return "Y"
        }
    }

    /// VoiceOver label for period segments.
    var accessibilityTitle: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }

    var statsDashboardWindow: StatsDashboardWindow {
        switch self {
        case .week: return .week
        case .month: return .month
        case .year: return .year
        }
    }
}

enum ProfileTargetMode: String, Sendable {
    case focusHackerDefault
    case personal
}

enum ProfileDashboardMetrics {
    static let defaultWeeklyMinutesTarget = 800

    static func profileHandle(from displayName: String) -> String {
        let slug = displayName
            .lowercased()
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map { String($0) }
            .joined()
        let trimmed = String(slug.prefix(20))
        if trimmed.isEmpty {
            return "@user"
        }
        return "@\(trimmed)"
    }

    static func weeklyMinutesProgressFraction(currentMinutes: Int, targetMinutes: Int = defaultWeeklyMinutesTarget) -> Double {
        let target = max(1, targetMinutes)
        return min(1, max(0, Double(currentMinutes) / Double(target)))
    }

    static func weeklyMinutesRemaining(currentMinutes: Int, targetMinutes: Int = defaultWeeklyMinutesTarget) -> Int {
        max(0, targetMinutes - currentMinutes)
    }

    static func weeklyMinutesPercentDisplay(currentMinutes: Int, targetMinutes: Int = defaultWeeklyMinutesTarget) -> Int {
        Int((weeklyMinutesProgressFraction(currentMinutes: currentMinutes, targetMinutes: targetMinutes) * 100).rounded())
    }
}

struct ProfileWeeklyGoalSnapshot: Sendable {
    let fraction: Double
    let percentDisplay: Int
    let currentMinutes: Int
    let targetMinutes: Int
}

enum ProfileChartTargets {
    static func dailyMinutes(fromWeekly weeklyMinutes: Int) -> Int {
        max(1, Int((Double(weeklyMinutes) / 7.0).rounded()))
    }
}

enum ProfileHeroMetrics {
    static let totalUnlockSegments = 10

    /// Segments filled on the achievement rail (Newcomer at 0 XP → 1; all tiers earned → 10).
    static func unlockedLevelCount(totalXP: Int) -> Int {
        let tierCount = FocusBadgeProgression.tiers.filter { totalXP >= $0.xpThreshold }.count
        return tierCount >= FocusBadgeProgression.tiers.count ? totalUnlockSegments : tierCount + 1
    }

    /// XP threshold shown for the next badge goal (max tier shows current badge threshold).
    static func nextBadgeXPDisplay(totalXP: Int) -> Int {
        FocusBadgeProgression.nextBadge(forTotalXP: totalXP)?.xpThreshold
            ?? FocusBadgeProgression.badge(forTotalXP: totalXP).xpThreshold
    }

    static func progressPercentDisplay(fraction: Double) -> String {
        "\(Int((min(1, max(0, fraction)) * 100).rounded()))%"
    }

    static func isMaxBadge(totalXP: Int) -> Bool {
        FocusBadgeProgression.nextBadge(forTotalXP: totalXP) == nil
    }

    static func xpProgressLabel(totalXP: Int) -> String {
        if isMaxBadge(totalXP: totalXP) {
            return "Max level reached"
        }
        let nextTitle = FocusBadgeProgression.nextBadge(forTotalXP: totalXP)?.title ?? ""
        return "Progress to \(nextTitle)"
    }

    /// Cumulative lifetime XP / next threshold with tier-relative percent in parentheses.
    static func xpProgressAmountText(totalXP: Int, tierRelativeFraction: Double) -> String {
        if isMaxBadge(totalXP: totalXP) {
            return formattedXP(totalXP)
        }
        let target = nextBadgeXPDisplay(totalXP: totalXP)
        let percent = progressPercentDisplay(fraction: tierRelativeFraction)
        return "\(formattedXP(totalXP)) / \(formattedXP(target)) (\(percent))"
    }

    static func xpProgressPercentText(fraction: Double) -> String {
        progressPercentDisplay(fraction: fraction)
    }

    /// Bar fill clamped to 2% minimum (spec) so zero progress is still visible.
    static func xpProgressBarFraction(fraction: Double) -> Double {
        let clamped = min(1, max(0, fraction))
        if clamped <= 0 { return 0.02 }
        return max(0.02, clamped)
    }

    static func levelPositionLabel(badgeLevel: Int, unlockedCount: Int) -> String {
        let displayLevel = badgeLevel + 1
        let position = min(unlockedCount, totalUnlockSegments)
        return "Level \(displayLevel) · \(position) / \(totalUnlockSegments)"
    }

    static func formattedXP(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = value >= 1_000
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
