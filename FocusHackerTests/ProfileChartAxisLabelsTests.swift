@testable import FocusHacker
import XCTest

final class ProfileChartAxisLabelsTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    func testMonthFiveDayLabelDatesIncludesFirstFifthGridAndLastDay() {
        let reference = date(2026, 5, 1)
        let monthStart = ProfileChartNavigation.currentMonthStart(now: reference, calendar: calendar)
        let chartReference = ProfileChartNavigation.chartReferenceDate(
            period: .month,
            weekStart: ProfileChartNavigation.currentWeekStart(now: reference, calendar: calendar),
            monthStart: monthStart,
            yearStart: ProfileChartNavigation.currentYearStart(now: reference, calendar: calendar),
            calendar: calendar
        )
        let buckets = FocusHoursChartBucketBuilder.build(
            window: .month,
            referenceNow: chartReference,
            calendar: calendar,
            completedSessions: []
        )
        let labelDates = ProfileChartAxisLabels.monthFiveDayLabelDates(from: buckets, calendar: calendar)
        let labelDays = labelDates.map { calendar.component(.day, from: $0) }

        XCTAssertEqual(labelDays.first, 1)
        XCTAssertTrue(labelDays.contains(6))
        XCTAssertTrue(labelDays.contains(11))
        XCTAssertTrue(labelDays.contains(16))
        XCTAssertTrue(labelDays.contains(21))
        XCTAssertTrue(labelDays.contains(26))
        XCTAssertEqual(labelDays.last, 31)
    }

    func testOrdinalSuffix() {
        XCTAssertEqual(ProfileChartAxisLabels.ordinalSuffix(for: 1), "st")
        XCTAssertEqual(ProfileChartAxisLabels.ordinalSuffix(for: 2), "nd")
        XCTAssertEqual(ProfileChartAxisLabels.ordinalSuffix(for: 3), "rd")
        XCTAssertEqual(ProfileChartAxisLabels.ordinalSuffix(for: 4), "th")
        XCTAssertEqual(ProfileChartAxisLabels.ordinalSuffix(for: 11), "th")
        XCTAssertEqual(ProfileChartAxisLabels.ordinalSuffix(for: 22), "nd")
    }

    func testMonthAxisLabelFormat() {
        let label = ProfileChartAxisLabels.monthAxisLabel(for: date(2026, 5, 1), calendar: calendar)
        XCTAssertEqual(label, "1st")
    }

    func testTooltipFocusDuration() {
        XCTAssertEqual(ProfileChartAxisLabels.tooltipFocusDuration(minutes: 0), "0h")
        XCTAssertEqual(ProfileChartAxisLabels.tooltipFocusDuration(minutes: 45), "45m")
        XCTAssertEqual(ProfileChartAxisLabels.tooltipFocusDuration(minutes: 60), "1h")
        XCTAssertEqual(ProfileChartAxisLabels.tooltipFocusDuration(minutes: 84), "1h 24m")
    }

    func testYearBucketsReturnTwelveMonths() {
        let reference = date(2026, 6, 1)
        let monthStart = ProfileChartNavigation.currentMonthStart(now: reference, calendar: calendar)
        let chartReference = ProfileChartNavigation.chartReferenceDate(
            period: .year,
            weekStart: ProfileChartNavigation.currentWeekStart(now: reference, calendar: calendar),
            monthStart: monthStart,
            yearStart: ProfileChartNavigation.currentYearStart(now: reference, calendar: calendar),
            calendar: calendar
        )
        let buckets = FocusHoursChartBucketBuilder.build(
            window: .year,
            referenceNow: chartReference,
            calendar: calendar,
            completedSessions: []
        )

        XCTAssertEqual(buckets.count, 12)
        XCTAssertEqual(buckets.first?.label, "Jan")
        XCTAssertEqual(buckets.last?.label, "Dec")
    }

    func testYearTooltipDateLabel() {
        let label = ProfileChartAxisLabels.tooltipDateLabel(
            for: date(2026, 3, 1),
            period: .year,
            calendar: calendar
        )
        XCTAssertTrue(label.contains("2026"))
        XCTAssertTrue(label.lowercased().contains("march"))
    }

    func testChartToggleCasesIncludesYear() {
        XCTAssertEqual(ProfileChartPeriod.chartToggleCases, [.week, .month, .year])
    }

    func testProfileChartPeriodUsesCalendarWindows() {
        XCTAssertEqual(ProfileChartPeriod.week.statsDashboardWindow, .week)
        XCTAssertEqual(ProfileChartPeriod.month.statsDashboardWindow, .month)
        XCTAssertEqual(ProfileChartPeriod.year.statsDashboardWindow, .year)
    }

    func testCanNavigateForwardOnlyForPastWeeksMonthsAndYears() {
        let now = date(2026, 5, 20)
        let currentWeek = ProfileChartNavigation.currentWeekStart(now: now, calendar: calendar)
        let currentMonth = ProfileChartNavigation.currentMonthStart(now: now, calendar: calendar)
        let currentYear = ProfileChartNavigation.currentYearStart(now: now, calendar: calendar)
        let priorWeek = ProfileChartNavigation.previousWeekStart(from: currentWeek, calendar: calendar)!
        let priorMonth = ProfileChartNavigation.previousMonthStart(from: currentMonth, calendar: calendar)!
        let priorYear = ProfileChartNavigation.previousYearStart(from: currentYear, calendar: calendar)!

        XCTAssertFalse(
            ProfileChartNavigation.canNavigateForward(
                period: .week,
                weekStart: currentWeek,
                monthStart: currentMonth,
                yearStart: currentYear,
                now: now,
                calendar: calendar
            )
        )
        XCTAssertTrue(
            ProfileChartNavigation.canNavigateForward(
                period: .week,
                weekStart: priorWeek,
                monthStart: currentMonth,
                yearStart: currentYear,
                now: now,
                calendar: calendar
            )
        )
        XCTAssertTrue(
            ProfileChartNavigation.canNavigateForward(
                period: .month,
                weekStart: currentWeek,
                monthStart: priorMonth,
                yearStart: currentYear,
                now: now,
                calendar: calendar
            )
        )
        XCTAssertFalse(
            ProfileChartNavigation.canNavigateForward(
                period: .year,
                weekStart: currentWeek,
                monthStart: currentMonth,
                yearStart: currentYear,
                now: now,
                calendar: calendar
            )
        )
        XCTAssertTrue(
            ProfileChartNavigation.canNavigateForward(
                period: .year,
                weekStart: currentWeek,
                monthStart: currentMonth,
                yearStart: priorYear,
                now: now,
                calendar: calendar
            )
        )
    }

    func testYearRangeTitle() {
        let yearStart = ProfileChartNavigation.currentYearStart(now: date(2026, 8, 1), calendar: calendar)
        XCTAssertEqual(ProfileChartNavigation.yearRangeTitle(yearStart: yearStart, calendar: calendar), "2026")
    }
}
