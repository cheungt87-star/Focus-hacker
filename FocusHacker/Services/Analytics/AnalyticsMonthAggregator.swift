import Foundation

enum AnalyticsMonthAggregator {
    static func summary(
        from records: [AnalyticsSessionRecord],
        monthStart: Date,
        calendar: Calendar = .current
    ) -> AnalyticsMonthSummary {
        let monthSubtitle = ProfileChartNavigation.monthRangeTitle(monthStart: monthStart, calendar: calendar)
        guard !records.isEmpty else {
            return AnalyticsMonthSummary(
                sessionCount: 0,
                totalFocusMinutes: 0,
                totalXP: 0,
                completionCount: 0,
                monthSubtitle: monthSubtitle
            )
        }

        let totalFocus = records.reduce(0) { $0 + $1.focusMinutes }
        let totalXP = records.reduce(0) { $0 + max(0, $1.xpAwarded) }
        let completionCount = records.filter(\.isNaturallyConcluded).count

        return AnalyticsMonthSummary(
            sessionCount: records.count,
            totalFocusMinutes: totalFocus,
            totalXP: totalXP,
            completionCount: completionCount,
            monthSubtitle: monthSubtitle
        )
    }
}
