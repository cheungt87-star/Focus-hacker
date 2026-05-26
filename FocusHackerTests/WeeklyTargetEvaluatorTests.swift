@testable import FocusHacker
import XCTest

final class WeeklyTargetEvaluatorTests: XCTestCase {
    func testFullWeekTargetHit() {
        let result = WeeklyTargetEvaluator.evaluate(
            WeeklyTargetEvaluationInput(
                weekStart: Date(),
                focusMinutes: 850,
                nominalDefaultTargetMinutes: 800,
                nominalPersonalTargetMinutes: 600,
                proRataDayCount: nil,
                isFirstPartialWeek: false
            )
        )
        XCTAssertTrue(result.defaultTargetHit)
        XCTAssertTrue(result.personalTargetHit)
        XCTAssertTrue(result.countsForDefaultStreak)
        XCTAssertTrue(result.countsForPersonalStreak)
    }

    func testPartialWeekProRata() {
        let result = WeeklyTargetEvaluator.evaluate(
            WeeklyTargetEvaluationInput(
                weekStart: Date(),
                focusMinutes: 500,
                nominalDefaultTargetMinutes: 800,
                nominalPersonalTargetMinutes: 600,
                proRataDayCount: 4,
                isFirstPartialWeek: true
            )
        )
        XCTAssertEqual(result.effectiveDefaultTargetMinutes, 458)
        XCTAssertTrue(result.defaultTargetHit)
        XCTAssertFalse(result.countsForDefaultStreak)
    }

    func testProRataDayCount() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = calendar.date(from: DateComponents(year: 2026, month: 5, day: 11))!
        let wednesday = calendar.date(from: DateComponents(year: 2026, month: 5, day: 13))!
        XCTAssertEqual(WeeklyTargetEvaluator.proRataDayCount(weekStart: monday, reference: wednesday, calendar: calendar), 3)
    }
}
