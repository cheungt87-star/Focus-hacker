import Foundation

enum ProfileChartNavigation {
    static func currentWeekStart(now: Date = Date(), calendar: Calendar = .current) -> Date {
        FocusCalendarWeekBounds.mondayStartOfWeek(containing: now, timeZone: calendar.timeZone)
    }

    static func currentMonthStart(now: Date = Date(), calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? calendar.startOfDay(for: now)
    }

    static func currentYearStart(now: Date = Date(), calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year], from: now)
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? calendar.startOfDay(for: now)
    }

    static func chartReferenceDate(
        period: ProfileChartPeriod,
        weekStart: Date,
        monthStart: Date,
        yearStart: Date,
        calendar: Calendar = .current
    ) -> Date {
        switch period {
        case .week:
            return calendar.date(byAdding: .day, value: 3, to: weekStart) ?? weekStart
        case .month:
            return calendar.date(byAdding: .day, value: 14, to: monthStart) ?? monthStart
        case .year:
            return yearStart
        }
    }

    static func canNavigateForward(
        period: ProfileChartPeriod,
        weekStart: Date,
        monthStart: Date,
        yearStart: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        switch period {
        case .week:
            return weekStart < currentWeekStart(now: now, calendar: calendar)
        case .month:
            return monthStart < currentMonthStart(now: now, calendar: calendar)
        case .year:
            return yearStart < currentYearStart(now: now, calendar: calendar)
        }
    }

    static func previousWeekStart(from weekStart: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .day, value: -7, to: weekStart)
    }

    static func nextWeekStart(from weekStart: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .day, value: 7, to: weekStart)
    }

    static func previousMonthStart(from monthStart: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .month, value: -1, to: monthStart)
    }

    static func nextMonthStart(from monthStart: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .month, value: 1, to: monthStart)
    }

    static func previousYearStart(from yearStart: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .year, value: -1, to: yearStart)
    }

    static func nextYearStart(from yearStart: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .year, value: 1, to: yearStart)
    }

    static func weekRangeTitle(weekStart: Date, calendar: Calendar = .current) -> String {
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return weekStart.formatted(.dateTime.month(.wide).year())
        }
        let startDay = calendar.component(.day, from: weekStart)
        let endDay = calendar.component(.day, from: weekEnd)
        let endMonthYear = weekEnd.formatted(.dateTime.month(.abbreviated).year())
        if calendar.isDate(weekStart, equalTo: weekEnd, toGranularity: .month) {
            return "\(startDay)–\(endDay) \(endMonthYear)"
        }
        let startMonth = weekStart.formatted(.dateTime.month(.abbreviated))
        let endMonth = weekEnd.formatted(.dateTime.month(.abbreviated))
        let year = weekEnd.formatted(.dateTime.year())
        return "\(startDay) \(startMonth) – \(endDay) \(endMonth) \(year)"
    }

    static func monthRangeTitle(monthStart: Date, calendar: Calendar = .current) -> String {
        monthStart.formatted(.dateTime.month(.wide).year())
    }

    static func yearRangeTitle(yearStart: Date, calendar: Calendar = .current) -> String {
        String(calendar.component(.year, from: yearStart))
    }
}
