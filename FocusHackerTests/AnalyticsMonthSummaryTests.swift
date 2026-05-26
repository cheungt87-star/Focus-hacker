import XCTest
@testable import FocusHacker

final class AnalyticsMonthSummaryTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func monthStart(_ year: Int, _ month: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = calendar.timeZone
        return calendar.date(from: components)!
    }

    func testEmptySummary() {
        let start = monthStart(2026, 5)
        let summary = AnalyticsMonthAggregator.summary(from: [], monthStart: start, calendar: calendar)
        XCTAssertEqual(summary.sessionCount, 0)
        XCTAssertEqual(summary.totalFocusMinutes, 0)
        XCTAssertEqual(summary.totalXP, 0)
        XCTAssertEqual(summary.completionCount, 0)
        XCTAssertEqual(summary.completionRatePercent, 0)
    }

    func testAggregatesSessionsFocusXPAndCompletion() {
        let start = monthStart(2026, 5)
        let records = [
            AnalyticsSessionRecord(
                id: "1",
                endedAt: start,
                startedAt: nil,
                focusMinutes: 60,
                xpAwarded: 90,
                isNaturallyConcluded: true
            ),
            AnalyticsSessionRecord(
                id: "2",
                endedAt: start,
                startedAt: nil,
                focusMinutes: 30,
                xpAwarded: 30,
                isNaturallyConcluded: false
            ),
            AnalyticsSessionRecord(
                id: "3",
                endedAt: start,
                startedAt: nil,
                focusMinutes: 10,
                xpAwarded: 0,
                isNaturallyConcluded: false
            ),
        ]
        let summary = AnalyticsMonthAggregator.summary(from: records, monthStart: start, calendar: calendar)
        XCTAssertEqual(summary.sessionCount, 3)
        XCTAssertEqual(summary.totalFocusMinutes, 100)
        XCTAssertEqual(summary.totalXP, 120)
        XCTAssertEqual(summary.completionCount, 1)
        XCTAssertEqual(summary.completionRatePercent, 33)
        XCTAssertEqual(summary.completionSubLabel, "1 of 3 finished")
    }
}
