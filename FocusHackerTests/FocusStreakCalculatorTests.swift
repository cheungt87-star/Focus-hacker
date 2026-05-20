@testable import FocusHacker
import XCTest

final class FocusStreakCalculatorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    func testCurrentStreakCountsActiveDaysWithTwoMissedGrace() {
        let reference = day(2026, 5, 16)
        let active: Set<Date> = [
            day(2026, 5, 16),
            day(2026, 5, 13),
            day(2026, 5, 10)
        ]

        let snapshot = FocusStreakCalculator.snapshot(
            activeDays: active,
            referenceNow: reference,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.currentStreak, 3)
    }

    func testCurrentStreakStopsAfterTwoMissedDaysBetweenActiveDays() {
        let reference = day(2026, 5, 16)
        let active: Set<Date> = [
            day(2026, 5, 16),
            day(2026, 5, 13)
        ]

        let snapshot = FocusStreakCalculator.snapshot(
            activeDays: active,
            referenceNow: reference,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.currentStreak, 2)
    }

    func testCurrentStreakBreaksAfterThreeConsecutiveMissedDays() {
        let reference = day(2026, 5, 16)
        let active: Set<Date> = [
            day(2026, 5, 16),
            day(2026, 5, 12)
        ]

        let snapshot = FocusStreakCalculator.snapshot(
            activeDays: active,
            referenceNow: reference,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.currentStreak, 1)
    }

    func testBestStreakAcrossHistory() {
        let reference = day(2026, 5, 20)
        let active: Set<Date> = [
            day(2026, 5, 1),
            day(2026, 5, 2),
            day(2026, 5, 5),
            day(2026, 5, 6),
            day(2026, 5, 7)
        ]

        let snapshot = FocusStreakCalculator.snapshot(
            activeDays: active,
            referenceNow: reference,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.bestStreak, 5)
    }

    func testRecentDayStatesReturnsSevenEntriesEndingToday() {
        let reference = day(2026, 5, 16)
        let active: Set<Date> = [day(2026, 5, 16), day(2026, 5, 14)]

        let snapshot = FocusStreakCalculator.snapshot(
            activeDays: active,
            referenceNow: reference,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.recentDayStates.count, 7)
        XCTAssertEqual(snapshot.recentDayStates.last, .completed)
        XCTAssertEqual(snapshot.recentDayStates[snapshot.recentDayStates.count - 3], .completed)
    }

    func testEmptyActiveDaysYieldsZeroStreaks() {
        let reference = day(2026, 5, 16)
        let snapshot = FocusStreakCalculator.snapshot(
            activeDays: [],
            referenceNow: reference,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.currentStreak, 0)
        XCTAssertEqual(snapshot.bestStreak, 0)
    }
}
