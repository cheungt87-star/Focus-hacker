@testable import FocusHacker
import XCTest

final class GamificationCalendarTests: XCTestCase {
    func testMondayWeekStartIsStableForKnownDate() {
        guard #available(macOS 14.0, *) else {
            XCTAssertTrue(true)
            return
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let wednesday = calendar.date(from: DateComponents(year: 2026, month: 5, day: 14, hour: 12))!
        let monday = FocusCalendarWeekBounds.mondayStartOfWeek(containing: wednesday, timeZone: calendar.timeZone)
        let end = FocusCalendarWeekBounds.exclusiveEndAfter(mondayStart: monday, timeZone: calendar.timeZone)
        XCTAssertEqual(end.timeIntervalSince(monday), 7 * 24 * 3_600, accuracy: 1)
    }

    func testWeeklyGamificationEvaluatorDoesNotEvaluateCurrentWeek() async throws {
        guard #available(macOS 14.0, *) else {
            XCTAssertTrue(true)
            return
        }
        guard let suiteDefaults = UserDefaults(suiteName: "fh.gamtests.\(UUID().uuidString)") else {
            XCTFail("Could not create suite defaults")
            return
        }
        let container = SwiftDataContainerFactory.makeInMemoryContainer()
        let settings = UserDefaultsSettingsStore(userDefaults: suiteDefaults, appGroupSuiteName: nil)
        let evaluator = SwiftDataWeeklyGamificationEvaluator(container: container, settingsStore: settings)
        let wednesday = Date()
        let first = try await evaluator.evaluatePendingClosedWeeks(now: wednesday)
        let second = try await evaluator.evaluatePendingClosedWeeks(now: wednesday)
        XCTAssertFalse(second.evaluatedAnyWeek)
        XCTAssertEqual(first.defaultTargetStreak, second.defaultTargetStreak)
    }
}
