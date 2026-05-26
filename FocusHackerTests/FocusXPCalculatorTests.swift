@testable import FocusHacker
import XCTest

final class FocusXPCalculatorTests: XCTestCase {
    func testNaturalCompletionAppliesOnePointFiveMultiplier() {
        XCTAssertEqual(FocusXPCalculator.xp(forFocusMinutes: 100, naturallyConcluded: true), 150)
        XCTAssertEqual(FocusXPCalculator.xp(forFocusMinutes: 45, naturallyConcluded: true), 68)
    }

    func testEarlyEndUsesBaseRate() {
        XCTAssertEqual(FocusXPCalculator.xp(forFocusMinutes: 100, naturallyConcluded: false), 100)
        XCTAssertEqual(FocusXPCalculator.xp(forFocusMinutes: 20, naturallyConcluded: false), 20)
    }

    func testZeroMinutesYieldsZeroXP() {
        XCTAssertEqual(FocusXPCalculator.xp(forFocusMinutes: 0, naturallyConcluded: true), 0)
        XCTAssertEqual(FocusXPCalculator.xp(forFocusMinutes: -5, naturallyConcluded: false), 0)
    }
}
