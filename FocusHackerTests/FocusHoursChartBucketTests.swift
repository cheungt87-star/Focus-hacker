@testable import FocusHacker
import XCTest

final class FocusHoursChartBucketTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testDayBucketsReturnsTwentyFourHours() {
        let reference = date(2026, 5, 16, hour: 15)
        let sessions = [
            (ended: date(2026, 5, 16, hour: 9), minutes: 25),
            (ended: date(2026, 5, 16, hour: 9), minutes: 10),
            (ended: date(2026, 5, 15, hour: 9), minutes: 50)
        ]

        let buckets = FocusHoursChartBucketBuilder.build(
            window: .day,
            referenceNow: reference,
            calendar: calendar,
            completedSessions: sessions
        )

        XCTAssertEqual(buckets.count, 24)
        XCTAssertEqual(buckets[9].focusMinutes, 35)
        XCTAssertEqual(buckets[8].focusMinutes, 0)
        XCTAssertEqual(buckets[9].label, "9a")
    }

    func testWeekBucketsReturnsSevenDays() {
        let reference = date(2026, 5, 14, hour: 12)
        let monday = FocusCalendarWeekBounds.mondayStartOfWeek(
            containing: reference,
            timeZone: calendar.timeZone
        )
        let sessions = [
            (ended: calendar.date(byAdding: .day, value: 1, to: monday)!, minutes: 40)
        ]

        let buckets = FocusHoursChartBucketBuilder.build(
            window: .week,
            referenceNow: reference,
            calendar: calendar,
            completedSessions: sessions
        )

        XCTAssertEqual(buckets.count, 7)
        XCTAssertTrue(buckets.contains { $0.focusMinutes == 40 })
    }

    func testMonthBucketsMatchDaysInMonth() {
        let reference = date(2026, 5, 10)
        let expectedDays = calendar.range(of: .day, in: .month, for: reference)?.count

        let buckets = FocusHoursChartBucketBuilder.build(
            window: .month,
            referenceNow: reference,
            calendar: calendar,
            completedSessions: [(ended: reference, minutes: 15)]
        )

        XCTAssertEqual(buckets.count, expectedDays)
        XCTAssertEqual(buckets[9].focusMinutes, 15)
    }

    func testYearBucketsReturnsTwelveMonths() {
        let reference = date(2026, 6, 1)
        let buckets = FocusHoursChartBucketBuilder.build(
            window: .year,
            referenceNow: reference,
            calendar: calendar,
            completedSessions: [
                (ended: date(2026, 3, 5), minutes: 20),
                (ended: date(2025, 12, 31), minutes: 99)
            ]
        )

        XCTAssertEqual(buckets.count, 12)
        XCTAssertEqual(buckets[2].focusMinutes, 20)
        XCTAssertEqual(buckets.reduce(0) { $0 + $1.focusMinutes }, 20)
    }

    func testRolling7BucketsReturnsSevenDaysEndingOnReferenceDay() {
        let reference = date(2026, 5, 20, hour: 15)
        let todayStart = calendar.startOfDay(for: reference)
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: todayStart)!
        let sessions = [
            (ended: sixDaysAgo, minutes: 30),
            (ended: reference, minutes: 45)
        ]

        let buckets = FocusHoursChartBucketBuilder.build(
            window: .rolling7,
            referenceNow: reference,
            calendar: calendar,
            completedSessions: sessions
        )

        XCTAssertEqual(buckets.count, 7)
        XCTAssertEqual(buckets.first?.periodStart, sixDaysAgo)
        XCTAssertEqual(buckets.last?.periodStart, todayStart)
        XCTAssertEqual(buckets.first?.focusMinutes, 30)
        XCTAssertEqual(buckets.last?.focusMinutes, 45)
    }

    func testRolling30BucketsReturnsThirtyDays() {
        let reference = date(2026, 5, 20)
        let buckets = FocusHoursChartBucketBuilder.build(
            window: .rolling30,
            referenceNow: reference,
            calendar: calendar,
            completedSessions: [(ended: reference, minutes: 60)]
        )

        XCTAssertEqual(buckets.count, 30)
        XCTAssertEqual(buckets.last?.focusMinutes, 60)
        XCTAssertEqual(buckets.dropLast().allSatisfy { $0.focusMinutes == 0 }, true)
    }

    func testRolling180And365BucketCounts() {
        let reference = date(2026, 5, 20)

        let rolling180 = FocusHoursChartBucketBuilder.build(
            window: .rolling180,
            referenceNow: reference,
            calendar: calendar,
            completedSessions: []
        )
        let rolling365 = FocusHoursChartBucketBuilder.build(
            window: .rolling365,
            referenceNow: reference,
            calendar: calendar,
            completedSessions: []
        )

        XCTAssertEqual(rolling180.count, 180)
        XCTAssertEqual(rolling365.count, 365)
        XCTAssertEqual(
            rolling180.first?.periodStart,
            calendar.date(byAdding: .day, value: -179, to: calendar.startOfDay(for: reference))
        )
        XCTAssertEqual(rolling365.last?.periodStart, calendar.startOfDay(for: reference))
    }

    func testProfileChartPeriodMapsToRollingWindows() {
        XCTAssertEqual(ProfileChartPeriod.week.statsDashboardWindow, .rolling7)
        XCTAssertEqual(ProfileChartPeriod.month.statsDashboardWindow, .rolling30)
        XCTAssertEqual(ProfileChartPeriod.sixMonths.statsDashboardWindow, .rolling180)
        XCTAssertEqual(ProfileChartPeriod.year.statsDashboardWindow, .rolling365)
        XCTAssertEqual(ProfileChartPeriod.year.rollingDayCount, 365)
    }
}
