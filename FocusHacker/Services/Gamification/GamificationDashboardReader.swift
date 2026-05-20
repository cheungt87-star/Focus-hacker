import Foundation
import SwiftData

/// ISO-8601 week boundaries (Monday start, `endExclusive` is the following Monday 00:00).
enum FocusCalendarWeekBounds {
    static func mondayStartOfWeek(containing date: Date, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? date
    }

    static func exclusiveEndAfter(mondayStart: Date, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone
        return calendar.date(byAdding: .weekOfYear, value: 1, to: mondayStart) ?? mondayStart.addingTimeInterval(7 * 24 * 3600)
    }
}

struct SessionMetricsSummary: Sendable {
    let totalCompletedFocusMinutes: Int
    let completedSessionCount: Int
    let initiatedSessionCount: Int

    var completionRateFraction: Double {
        guard initiatedSessionCount > 0 else { return 0 }
        return Double(completedSessionCount) / Double(initiatedSessionCount)
    }
}

struct FocusHoursChartBucket: Identifiable, Sendable {
    let id: String
    let label: String
    let focusMinutes: Int
    let periodStart: Date
}

enum StatsDashboardWindow: String, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month
    case year
    case rolling7
    case rolling30
    case rolling180
    case rolling365

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .rolling7: return "Week"
        case .rolling30: return "Month"
        case .rolling180: return "6 mo"
        case .rolling365: return "Year"
        }
    }

    var rollingDayCount: Int? {
        switch self {
        case .rolling7: return 7
        case .rolling30: return 30
        case .rolling180: return 180
        case .rolling365: return 365
        default: return nil
        }
    }

    func inclusiveStartDate(referenceNow: Date, calendar: Calendar) -> Date? {
        switch self {
        case .day:
            return calendar.startOfDay(for: referenceNow)
        case .week:
            return FocusCalendarWeekBounds.mondayStartOfWeek(containing: referenceNow, timeZone: calendar.timeZone)
        case .month:
            var comps = calendar.dateComponents([.year, .month], from: referenceNow)
            comps.day = 1
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            return calendar.date(from: comps)
        case .year:
            var comps = calendar.dateComponents([.year], from: referenceNow)
            comps.month = 1
            comps.day = 1
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            return calendar.date(from: comps)
        case .rolling7, .rolling30, .rolling180, .rolling365:
            guard let dayCount = rollingDayCount,
                  let endDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: referenceNow))
            else {
                return nil
            }
            return calendar.date(byAdding: .day, value: -dayCount, to: endDay)
        }
    }
}

protocol GamificationDashboardReading: Sendable {
    func totalAccumulatedXP() async throws -> Int
    func xpEarnedInExclusiveRange(start: Date, endExclusive: Date) async throws -> Int
    func sessionMetricsEndedAtInExclusiveRange(start: Date, endExclusive: Date) async throws -> SessionMetricsSummary
    func completedSessionCalendarDays() async throws -> Set<Date>
    func focusHoursChartBuckets(
        window: StatsDashboardWindow,
        referenceNow: Date,
        calendar: Calendar
    ) async throws -> [FocusHoursChartBucket]
}

@available(macOS 14.0, *)
struct SwiftDataGamificationDashboardReader: GamificationDashboardReading, @unchecked Sendable {
    let container: ModelContainer

    func totalAccumulatedXP() async throws -> Int {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<XPRecord>())
        return records.reduce(0) { $0 + max(0, $1.xpAmount) }
    }

    func xpEarnedInExclusiveRange(start: Date, endExclusive: Date) async throws -> Int {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<XPRecord>())
        return records.reduce(0) { partial, record in
            guard record.createdAt >= start, record.createdAt < endExclusive else { return partial }
            return partial + max(0, record.xpAmount)
        }
    }

    func sessionMetricsEndedAtInExclusiveRange(start: Date, endExclusive: Date) async throws -> SessionMetricsSummary {
        let context = ModelContext(container)
        let sessions = try context.fetch(FetchDescriptor<Session>())
        var initiated = 0
        var completed = 0
        var totalFocus = 0
        for session in sessions {
            guard let ended = session.endedAt else { continue }
            guard ended >= start, ended < endExclusive else { continue }
            initiated += 1
            if session.didComplete == true {
                completed += 1
                totalFocus += max(0, session.totalFocusMinutes ?? session.focusDurationMinutes)
            }
        }
        return SessionMetricsSummary(
            totalCompletedFocusMinutes: totalFocus,
            completedSessionCount: completed,
            initiatedSessionCount: initiated
        )
    }

    func completedSessionCalendarDays() async throws -> Set<Date> {
        let context = ModelContext(container)
        let sessions = try context.fetch(FetchDescriptor<Session>())
        var days = Set<Date>()
        let calendar = Calendar.current
        for session in sessions {
            guard session.didComplete == true, let ended = session.endedAt else { continue }
            days.insert(calendar.startOfDay(for: ended))
        }
        return days
    }

    func focusHoursChartBuckets(
        window: StatsDashboardWindow,
        referenceNow: Date,
        calendar: Calendar
    ) async throws -> [FocusHoursChartBucket] {
        let context = ModelContext(container)
        let sessions = try context.fetch(FetchDescriptor<Session>())
        let completed = sessions.compactMap { session -> (ended: Date, minutes: Int)? in
            guard session.didComplete == true, let ended = session.endedAt else { return nil }
            let minutes = max(0, session.totalFocusMinutes ?? session.focusDurationMinutes)
            return (ended, minutes)
        }
        return FocusHoursChartBucketBuilder.build(
            window: window,
            referenceNow: referenceNow,
            calendar: calendar,
            completedSessions: completed
        )
    }
}

enum FocusHoursChartBucketBuilder {
    static func build(
        window: StatsDashboardWindow,
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int)]
    ) -> [FocusHoursChartBucket] {
        switch window {
        case .day:
            return dayBuckets(referenceNow: referenceNow, calendar: calendar, completedSessions: completedSessions)
        case .week:
            return weekBuckets(referenceNow: referenceNow, calendar: calendar, completedSessions: completedSessions)
        case .month:
            return monthBuckets(referenceNow: referenceNow, calendar: calendar, completedSessions: completedSessions)
        case .year:
            return yearBuckets(referenceNow: referenceNow, calendar: calendar, completedSessions: completedSessions)
        case .rolling7, .rolling30, .rolling180, .rolling365:
            guard let dayCount = window.rollingDayCount else { return [] }
            return rollingDailyBuckets(
                dayCount: dayCount,
                referenceNow: referenceNow,
                calendar: calendar,
                completedSessions: completedSessions
            )
        }
    }

    static func rollingDailyBuckets(
        dayCount: Int,
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int)]
    ) -> [FocusHoursChartBucket] {
        let todayStart = calendar.startOfDay(for: referenceNow)
        guard dayCount > 0 else { return [] }

        return (0..<dayCount).compactMap { index -> FocusHoursChartBucket? in
            let daysFromStart = index - (dayCount - 1)
            guard let dayStart = calendar.date(byAdding: .day, value: daysFromStart, to: todayStart),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)
            else {
                return nil
            }
            let total = completedSessions
                .filter { $0.ended >= dayStart && $0.ended < dayEnd }
                .reduce(0) { $0 + $1.minutes }
            let weekday = dayStart.formatted(.dateTime.weekday(.abbreviated))
            let dayNumber = calendar.component(.day, from: dayStart)
            return FocusHoursChartBucket(
                id: "rolling-\(dayStart.timeIntervalSince1970)",
                label: "\(weekday) \(dayNumber)",
                focusMinutes: total,
                periodStart: dayStart
            )
        }
    }

    private static func dayBuckets(
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int)]
    ) -> [FocusHoursChartBucket] {
        let dayStart = calendar.startOfDay(for: referenceNow)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

        var minutesByHour = [Int: Int]()
        for session in completedSessions where session.ended >= dayStart && session.ended < dayEnd {
            let hour = calendar.component(.hour, from: session.ended)
            minutesByHour[hour, default: 0] += session.minutes
        }

        return (0..<24).map { hour in
            let periodStart = calendar.date(byAdding: .hour, value: hour, to: dayStart) ?? dayStart
            return FocusHoursChartBucket(
                id: "hour-\(hour)",
                label: hourLabel(hour),
                focusMinutes: minutesByHour[hour, default: 0],
                periodStart: periodStart
            )
        }
    }

    private static func weekBuckets(
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int)]
    ) -> [FocusHoursChartBucket] {
        let weekStart = FocusCalendarWeekBounds.mondayStartOfWeek(
            containing: referenceNow,
            timeZone: calendar.timeZone
        )
        let weekdaySymbols = calendar.shortWeekdaySymbols

        return (0..<7).compactMap { offset -> FocusHoursChartBucket? in
            guard let dayStart = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
            let total = completedSessions
                .filter { $0.ended >= dayStart && $0.ended < dayEnd }
                .reduce(0) { $0 + $1.minutes }
            let weekdayIndex = calendar.component(.weekday, from: dayStart) - 1
            let label = weekdaySymbols.indices.contains(weekdayIndex)
                ? weekdaySymbols[weekdayIndex]
                : dayStart.formatted(.dateTime.weekday(.abbreviated))
            return FocusHoursChartBucket(
                id: "weekday-\(offset)",
                label: label,
                focusMinutes: total,
                periodStart: dayStart
            )
        }
    }

    private static func monthBuckets(
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int)]
    ) -> [FocusHoursChartBucket] {
        guard let monthStart = windowInclusiveStart(.month, referenceNow: referenceNow, calendar: calendar),
              let range = calendar.range(of: .day, in: .month, for: referenceNow)
        else {
            return []
        }
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? referenceNow

        return range.map { day in
            var components = calendar.dateComponents([.year, .month], from: monthStart)
            components.day = day
            let dayStart = calendar.date(from: components) ?? monthStart
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let total = completedSessions
                .filter { $0.ended >= dayStart && $0.ended < min(dayEnd, monthEnd) }
                .reduce(0) { $0 + $1.minutes }
            return FocusHoursChartBucket(
                id: "month-day-\(day)",
                label: "\(day)",
                focusMinutes: total,
                periodStart: dayStart
            )
        }
    }

    private static func yearBuckets(
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int)]
    ) -> [FocusHoursChartBucket] {
        guard let yearStart = windowInclusiveStart(.year, referenceNow: referenceNow, calendar: calendar) else {
            return []
        }

        return (1...12).compactMap { month -> FocusHoursChartBucket? in
            var startComponents = calendar.dateComponents([.year], from: yearStart)
            startComponents.month = month
            startComponents.day = 1
            guard let monthStart = calendar.date(from: startComponents),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)
            else {
                return nil
            }
            let total = completedSessions
                .filter { $0.ended >= monthStart && $0.ended < monthEnd }
                .reduce(0) { $0 + $1.minutes }
            let label = monthStart.formatted(.dateTime.month(.abbreviated))
            return FocusHoursChartBucket(
                id: "year-month-\(month)",
                label: label,
                focusMinutes: total,
                periodStart: monthStart
            )
        }
    }

    private static func windowInclusiveStart(
        _ window: StatsDashboardWindow,
        referenceNow: Date,
        calendar: Calendar
    ) -> Date? {
        window.inclusiveStartDate(referenceNow: referenceNow, calendar: calendar)
    }

    private static func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        case 1...11: return "\(hour)a"
        default: return "\(hour - 12)p"
        }
    }
}

struct NoOpGamificationDashboardReader: GamificationDashboardReading {
    func totalAccumulatedXP() async throws -> Int { 0 }

    func xpEarnedInExclusiveRange(start: Date, endExclusive: Date) async throws -> Int { 0 }

    func sessionMetricsEndedAtInExclusiveRange(start: Date, endExclusive: Date) async throws -> SessionMetricsSummary {
        SessionMetricsSummary(totalCompletedFocusMinutes: 0, completedSessionCount: 0, initiatedSessionCount: 0)
    }

    func completedSessionCalendarDays() async throws -> Set<Date> { [] }

    func focusHoursChartBuckets(
        window: StatsDashboardWindow,
        referenceNow: Date,
        calendar: Calendar
    ) async throws -> [FocusHoursChartBucket] {
        FocusHoursChartBucketBuilder.build(
            window: window,
            referenceNow: referenceNow,
            calendar: calendar,
            completedSessions: []
        )
    }
}

extension SessionMetricsSummary {
    static let empty = SessionMetricsSummary(
        totalCompletedFocusMinutes: 0,
        completedSessionCount: 0,
        initiatedSessionCount: 0
    )
}
