import Foundation

enum AnalyticsMonthFilter {
    static func monthEndExclusive(
        monthStart: Date,
        calendar: Calendar = .current
    ) -> Date? {
        calendar.date(byAdding: .month, value: 1, to: monthStart)
    }

    static func sessions(
        inMonthStarting monthStart: Date,
        from records: [AnalyticsSessionRecord],
        calendar: Calendar = .current
    ) -> [AnalyticsSessionRecord] {
        guard let endExclusive = monthEndExclusive(monthStart: monthStart, calendar: calendar) else {
            return []
        }
        return records.filter { record in
            record.endedAt >= monthStart && record.endedAt < endExclusive
        }
    }
}
