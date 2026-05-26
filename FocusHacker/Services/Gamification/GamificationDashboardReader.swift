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
    let xpEarned: Int
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
    /// Focus minutes from sessions that earned XP (includes early-ended sessions).
    func focusMinutesAwardedInExclusiveRange(start: Date, endExclusive: Date) async throws -> Int
    func completedSessionCalendarDays() async throws -> Set<Date>
    /// All sessions with an end time (completed and early-ended).
    func lifetimeEndedSessionCount() async throws -> Int
    func focusHoursChartBuckets(
        window: StatsDashboardWindow,
        referenceNow: Date,
        calendar: Calendar
    ) async throws -> [FocusHoursChartBucket]
}

@available(macOS 14.0, *)
enum GamificationSessionAggregation {
    static func focusMinutes(from session: Session) -> Int {
        max(0, session.totalFocusMinutes ?? session.focusDurationMinutes)
    }

    static func countsForWeeklyTarget(_ session: Session) -> Bool {
        session.endedAt != nil && session.xpAwarded > 0
    }
}

@available(macOS 14.0, *)
struct SwiftDataGamificationDashboardReader: GamificationDashboardReading, @unchecked Sendable {
    let container: ModelContainer
    let settingsStore: UserDefaultsSettingsStore

    func totalAccumulatedXP() async throws -> Int {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<XPRecord>())
        return LifetimeXPFiltering.sumLifetimeXP(from: records, resetAt: settingsStore.lifetimeXPResetAt)
    }

    func xpEarnedInExclusiveRange(start: Date, endExclusive: Date) async throws -> Int {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<XPRecord>())
        let resetAt = settingsStore.lifetimeXPResetAt
        return records.reduce(0) { partial, record in
            guard record.createdAt >= start, record.createdAt < endExclusive else { return partial }
            guard LifetimeXPFiltering.countsTowardLifetimeXP(record, resetAt: resetAt) else { return partial }
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
                totalFocus += GamificationSessionAggregation.focusMinutes(from: session)
            }
        }
        return SessionMetricsSummary(
            totalCompletedFocusMinutes: totalFocus,
            completedSessionCount: completed,
            initiatedSessionCount: initiated
        )
    }

    func focusMinutesAwardedInExclusiveRange(start: Date, endExclusive: Date) async throws -> Int {
        let context = ModelContext(container)
        let sessions = try context.fetch(FetchDescriptor<Session>())
        var matched = 0
        let total = sessions.reduce(0) { partial, session in
            guard GamificationSessionAggregation.countsForWeeklyTarget(session),
                  let ended = session.endedAt,
                  ended >= start,
                  ended < endExclusive
            else {
                return partial
            }
            matched += 1
            return partial + GamificationSessionAggregation.focusMinutes(from: session)
        }
        // #region agent log
        DebugSessionLogAfdf58.write(
            hypothesisId: "H5",
            location: "GamificationDashboardReader.focusMinutesAwarded",
            message: "week_query",
            data: [
                "sessionCount": "\(sessions.count)",
                "matchedInWeek": "\(matched)",
                "totalMinutes": "\(total)",
                "weekStart": "\(start.timeIntervalSince1970)",
                "weekEnd": "\(endExclusive.timeIntervalSince1970)",
            ]
        )
        // #endregion
        return total
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

    func lifetimeEndedSessionCount() async throws -> Int {
        let context = ModelContext(container)
        let sessions = try context.fetch(FetchDescriptor<Session>())
        return sessions.reduce(0) { count, session in
            session.endedAt != nil ? count + 1 : count
        }
    }

    func focusHoursChartBuckets(
        window: StatsDashboardWindow,
        referenceNow: Date,
        calendar: Calendar
    ) async throws -> [FocusHoursChartBucket] {
        let context = ModelContext(container)
        let sessions = try context.fetch(FetchDescriptor<Session>())
        var excludedNoEnd = 0
        var excludedNoXP = 0
        var included = 0
        let completed = sessions.compactMap { session -> (ended: Date, minutes: Int, xp: Int)? in
            if session.endedAt == nil {
                excludedNoEnd += 1
                return nil
            }
            if session.xpAwarded <= 0 {
                excludedNoXP += 1
                return nil
            }
            guard GamificationSessionAggregation.countsForWeeklyTarget(session),
                  let ended = session.endedAt
            else {
                return nil
            }
            included += 1
            return (
                ended,
                GamificationSessionAggregation.focusMinutes(from: session),
                max(0, session.xpAwarded)
            )
        }
        let buckets = FocusHoursChartBucketBuilder.build(
            window: window,
            referenceNow: referenceNow,
            calendar: calendar,
            completedSessions: completed
        )
        let weekStart = FocusCalendarWeekBounds.mondayStartOfWeek(
            containing: referenceNow,
            timeZone: calendar.timeZone
        )
        let todayStart = calendar.startOfDay(for: referenceNow)
        let mondayBucket = buckets.first { calendar.isDate($0.periodStart, inSameDayAs: weekStart) }
        let todayBucket = buckets.first { calendar.isDate($0.periodStart, inSameDayAs: todayStart) }
        let recentSessions = sessions
            .filter { $0.endedAt != nil }
            .sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) }
            .prefix(3)
            .map { session -> String in
                let ended = session.endedAt ?? Date()
                let minutes = GamificationSessionAggregation.focusMinutes(from: session)
                return "xp=\(session.xpAwarded),min=\(minutes),ended=\(Int(ended.timeIntervalSince1970)),day=\(calendar.startOfDay(for: ended).timeIntervalSince1970)"
            }
            .joined(separator: "|")
        // #region agent log
        DebugSessionLog5cee87.write(
            hypothesisId: "H1-H4",
            location: "GamificationDashboardReader.focusHoursChartBuckets",
            message: "chart_query",
            data: [
                "window": window.rawValue,
                "sessionCount": "\(sessions.count)",
                "included": "\(included)",
                "excludedNoEnd": "\(excludedNoEnd)",
                "excludedNoXP": "\(excludedNoXP)",
                "referenceNow": "\(Int(referenceNow.timeIntervalSince1970))",
                "weekStart": "\(Int(weekStart.timeIntervalSince1970))",
                "todayStart": "\(Int(todayStart.timeIntervalSince1970))",
                "timeZone": calendar.timeZone.identifier,
                "mondayBucketMinutes": "\(mondayBucket?.focusMinutes ?? -1)",
                "mondayBucketXP": "\(mondayBucket?.xpEarned ?? -1)",
                "todayBucketMinutes": "\(todayBucket?.focusMinutes ?? -1)",
                "bucketCount": "\(buckets.count)",
                "recentSessions": recentSessions,
            ]
        )
        let bucketMinutesSum = buckets.reduce(0) { $0 + $1.focusMinutes }
        let sessionMinutesSum = completed.reduce(0) { $0 + $1.minutes }
        let yearMinutesSum = window == .year ? bucketMinutesSum : -1
        DebugSessionLogAc92a4.write(
            hypothesisId: "H1-H4",
            location: "GamificationDashboardReader.focusHoursChartBuckets",
            message: "chart_query",
            data: [
                "window": window.rawValue,
                "sessionCount": "\(sessions.count)",
                "included": "\(included)",
                "excludedNoEnd": "\(excludedNoEnd)",
                "excludedNoXP": "\(excludedNoXP)",
                "referenceNow": "\(Int(referenceNow.timeIntervalSince1970))",
                "weekStart": "\(Int(weekStart.timeIntervalSince1970))",
                "todayStart": "\(Int(todayStart.timeIntervalSince1970))",
                "todayBucketMinutes": "\(todayBucket?.focusMinutes ?? -1)",
                "bucketMinutesSum": "\(bucketMinutesSum)",
                "sessionMinutesSum": "\(sessionMinutesSum)",
                "yearMinutesSum": "\(yearMinutesSum)",
                "nonZeroBuckets": "\(buckets.filter { $0.focusMinutes > 0 }.count)",
                "recentSessions": recentSessions,
            ]
        )
        // #endregion
        return buckets
    }
}

enum FocusHoursChartBucketBuilder {
    static func build(
        window: StatsDashboardWindow,
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int, xp: Int)]
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
        completedSessions: [(ended: Date, minutes: Int, xp: Int)]
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
            let daySessions = completedSessions.filter { $0.ended >= dayStart && $0.ended < dayEnd }
            let totalMinutes = daySessions.reduce(0) { $0 + $1.minutes }
            let totalXP = daySessions.reduce(0) { $0 + $1.xp }
            let weekday = dayStart.formatted(.dateTime.weekday(.abbreviated))
            let dayNumber = calendar.component(.day, from: dayStart)
            return FocusHoursChartBucket(
                id: "rolling-\(dayStart.timeIntervalSince1970)",
                label: "\(weekday) \(dayNumber)",
                focusMinutes: totalMinutes,
                xpEarned: totalXP,
                periodStart: dayStart
            )
        }
    }

    private static func dayBuckets(
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int, xp: Int)]
    ) -> [FocusHoursChartBucket] {
        let dayStart = calendar.startOfDay(for: referenceNow)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

        var minutesByHour = [Int: Int]()
        var xpByHour = [Int: Int]()
        for session in completedSessions where session.ended >= dayStart && session.ended < dayEnd {
            let hour = calendar.component(.hour, from: session.ended)
            minutesByHour[hour, default: 0] += session.minutes
            xpByHour[hour, default: 0] += session.xp
        }

        return (0..<24).map { hour in
            let periodStart = calendar.date(byAdding: .hour, value: hour, to: dayStart) ?? dayStart
            return FocusHoursChartBucket(
                id: "hour-\(hour)",
                label: hourLabel(hour),
                focusMinutes: minutesByHour[hour, default: 0],
                xpEarned: xpByHour[hour, default: 0],
                periodStart: periodStart
            )
        }
    }

    private static func weekBuckets(
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int, xp: Int)]
    ) -> [FocusHoursChartBucket] {
        let weekStart = FocusCalendarWeekBounds.mondayStartOfWeek(
            containing: referenceNow,
            timeZone: calendar.timeZone
        )
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let todayStart = calendar.startOfDay(for: referenceNow)
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)
        let todaySessions = completedSessions.filter { session in
            guard let todayEnd else { return false }
            return session.ended >= todayStart && session.ended < todayEnd
        }
        // #region agent log
        DebugSessionLogAc92a4.write(
            hypothesisId: "H4",
            location: "FocusHoursChartBucketBuilder.weekBuckets",
            message: "day_bounds",
            data: [
                "referenceNow": "\(Int(referenceNow.timeIntervalSince1970))",
                "weekStart": "\(Int(weekStart.timeIntervalSince1970))",
                "todayStart": "\(Int(todayStart.timeIntervalSince1970))",
                "todayEnd": "\(Int((todayEnd ?? todayStart).timeIntervalSince1970))",
                "completedSessionCount": "\(completedSessions.count)",
                "todaySessionCount": "\(todaySessions.count)",
                "todaySessionMinutes": "\(todaySessions.reduce(0) { $0 + $1.minutes })",
            ]
        )
        // #endregion

        return (0..<7).compactMap { offset -> FocusHoursChartBucket? in
            guard let dayStart = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
            let daySessions = completedSessions.filter { $0.ended >= dayStart && $0.ended < dayEnd }
            let totalMinutes = daySessions.reduce(0) { $0 + $1.minutes }
            let totalXP = daySessions.reduce(0) { $0 + $1.xp }
            let weekdayIndex = calendar.component(.weekday, from: dayStart) - 1
            let label = weekdaySymbols.indices.contains(weekdayIndex)
                ? weekdaySymbols[weekdayIndex]
                : dayStart.formatted(.dateTime.weekday(.abbreviated))
            return FocusHoursChartBucket(
                id: "week-\(Int(dayStart.timeIntervalSince1970))",
                label: label,
                focusMinutes: totalMinutes,
                xpEarned: totalXP,
                periodStart: dayStart
            )
        }
    }

    private static func monthBuckets(
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int, xp: Int)]
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
            let daySessions = completedSessions.filter { $0.ended >= dayStart && $0.ended < min(dayEnd, monthEnd) }
            let totalMinutes = daySessions.reduce(0) { $0 + $1.minutes }
            let totalXP = daySessions.reduce(0) { $0 + $1.xp }
            return FocusHoursChartBucket(
                id: "month-\(Int(dayStart.timeIntervalSince1970))",
                label: "\(day)",
                focusMinutes: totalMinutes,
                xpEarned: totalXP,
                periodStart: dayStart
            )
        }
    }

    private static func yearBuckets(
        referenceNow: Date,
        calendar: Calendar,
        completedSessions: [(ended: Date, minutes: Int, xp: Int)]
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
            let monthSessions = completedSessions.filter { $0.ended >= monthStart && $0.ended < monthEnd }
            let totalMinutes = monthSessions.reduce(0) { $0 + $1.minutes }
            let totalXP = monthSessions.reduce(0) { $0 + $1.xp }
            let label = monthStart.formatted(.dateTime.month(.abbreviated))
            return FocusHoursChartBucket(
                id: "year-\(Int(monthStart.timeIntervalSince1970))",
                label: label,
                focusMinutes: totalMinutes,
                xpEarned: totalXP,
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

    func focusMinutesAwardedInExclusiveRange(start: Date, endExclusive: Date) async throws -> Int { 0 }

    func completedSessionCalendarDays() async throws -> Set<Date> { [] }

    func lifetimeEndedSessionCount() async throws -> Int { 0 }

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
