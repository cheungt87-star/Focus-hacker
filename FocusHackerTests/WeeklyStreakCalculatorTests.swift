@testable import FocusHacker
import XCTest

final class WeeklyStreakCalculatorTests: XCTestCase {
    private func week(_ offset: Int) -> Date {
        Date(timeIntervalSince1970: Double(offset) * 7 * 24 * 3_600)
    }

    func testCurrentAndLongestStreaks() {
        let weeks: [WeeklyStreakWeekInput] = [
            WeeklyStreakWeekInput(weekStart: week(0), defaultTargetHit: true, personalTargetHit: true),
            WeeklyStreakWeekInput(weekStart: week(1), defaultTargetHit: true, personalTargetHit: false),
            WeeklyStreakWeekInput(weekStart: week(2), defaultTargetHit: false, personalTargetHit: true),
            WeeklyStreakWeekInput(weekStart: week(3), defaultTargetHit: true, personalTargetHit: true)
        ]
        let snapshot = WeeklyStreakCalculator.snapshot(closedWeeks: weeks)
        XCTAssertEqual(snapshot.defaultStreak, 1)
        XCTAssertEqual(snapshot.personalStreak, 2)
        XCTAssertEqual(snapshot.longestDefaultStreak, 2)
        XCTAssertEqual(snapshot.longestPersonalStreak, 2)
    }

    func testEmptyWeeks() {
        let snapshot = WeeklyStreakCalculator.snapshot(closedWeeks: [])
        XCTAssertEqual(snapshot.defaultStreak, 0)
        XCTAssertEqual(snapshot.personalStreak, 0)
    }
}
