import XCTest
@testable import FocusHacker

final class AnalyticsMonthFilterTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = 0
        components.second = 0
        components.timeZone = calendar.timeZone
        return calendar.date(from: components)!
    }

    private func record(endedAt: Date) -> AnalyticsSessionRecord {
        AnalyticsSessionRecord(
            id: "\(endedAt.timeIntervalSince1970)",
            endedAt: endedAt,
            startedAt: endedAt.addingTimeInterval(-3600),
            focusMinutes: 25,
            xpAwarded: 25,
            isNaturallyConcluded: true
        )
    }

    func testSessionsInMonthIncludesBoundaries() {
        let monthStart = date(2026, 5, 1, hour: 0)
        let inMonth = record(endedAt: date(2026, 5, 15))
        let lastDay = record(endedAt: date(2026, 5, 31, hour: 23))
        let nextMonth = record(endedAt: date(2026, 6, 1, hour: 0))
        let priorMonth = record(endedAt: date(2026, 4, 30, hour: 23))

        let filtered = AnalyticsMonthFilter.sessions(
            inMonthStarting: monthStart,
            from: [inMonth, lastDay, nextMonth, priorMonth],
            calendar: calendar
        )

        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains(where: { $0.id == inMonth.id }))
        XCTAssertTrue(filtered.contains(where: { $0.id == lastDay.id }))
    }
}
