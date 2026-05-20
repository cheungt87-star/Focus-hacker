import Foundation

/// UI chart period for the profile dashboard (maps to `StatsDashboardWindow` for data fetch).
enum ProfileChartPeriod: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case sixMonths
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .sixMonths: return "6 mo"
        case .year: return "Year"
        }
    }

    /// Compact label for the profile chart period toggle (W, M, 6M, Y).
    var shortTitle: String {
        switch self {
        case .week: return "W"
        case .month: return "M"
        case .sixMonths: return "6M"
        case .year: return "Y"
        }
    }

    /// VoiceOver label for period segments.
    var accessibilityTitle: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .sixMonths: return "6 months"
        case .year: return "Year"
        }
    }

    var rollingDayCount: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .sixMonths: return 180
        case .year: return 365
        }
    }

    var statsDashboardWindow: StatsDashboardWindow {
        switch self {
        case .week: return .rolling7
        case .month: return .rolling30
        case .sixMonths: return .rolling180
        case .year: return .rolling365
        }
    }

    /// Days between x-axis labels for readable charts at longer ranges.
    var xAxisLabelStrideDays: Int {
        switch self {
        case .week: return 1
        case .month: return 5
        case .sixMonths: return 14
        case .year: return 30
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

/// Placeholder hero metrics until weekly streaks and badge XP thresholds are wired.
enum ProfileHeroPlaceholder {
    static let nextLevelTitle = "Hall of Famer"
    static let nextLevelXPThreshold = 84_000
    static let mockLifetimeXP = 36_000
    static let mockProgressFraction = 0.57
    static let mockXPGap = nextLevelXPThreshold - mockLifetimeXP
    static let mockCurrentStreakWeeks = 12
    static let mockLongestStreakWeeks = 24

    static var mockProgressPercentDisplay: Int {
        Int((mockProgressFraction * 100).rounded())
    }
}

/// Mock and conversion helpers for chart target reference lines (backend wiring later).
enum ProfileChartTargets {
    static let mockWeeklyPersonalMinutes = 600

    static func dailyMinutes(fromWeekly weeklyMinutes: Int) -> Int {
        max(1, Int((Double(weeklyMinutes) / 7.0).rounded()))
    }

    static var mockFocusHackerDailyMinutes: Int {
        dailyMinutes(fromWeekly: ProfileDashboardMetrics.defaultWeeklyMinutesTarget)
    }

    static var mockPersonalDailyMinutes: Int {
        dailyMinutes(fromWeekly: mockWeeklyPersonalMinutes)
    }
}
