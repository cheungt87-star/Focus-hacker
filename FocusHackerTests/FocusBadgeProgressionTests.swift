@testable import FocusHacker
import XCTest

final class FocusBadgeProgressionTests: XCTestCase {
    func testBadgeForTotalXP() {
        XCTAssertEqual(FocusBadgeProgression.badge(forTotalXP: 0).title, "Newcomer")
        XCTAssertEqual(FocusBadgeProgression.badge(forTotalXP: 999).title, "Newcomer")
        XCTAssertEqual(FocusBadgeProgression.badge(forTotalXP: 1_000).title, "Rookie")
        XCTAssertEqual(FocusBadgeProgression.badge(forTotalXP: 36_000).title, "Champion")
        XCTAssertEqual(FocusBadgeProgression.badge(forTotalXP: 200_000).title, "GOAT")
    }

    func testNextBadgeAndProgress() {
        XCTAssertEqual(FocusBadgeProgression.nextBadge(forTotalXP: 500)?.title, "Rookie")
        XCTAssertEqual(FocusBadgeProgression.progressFractionToNext(totalXP: 500), 0.5, accuracy: 0.01)
        XCTAssertEqual(FocusBadgeProgression.nextBadge(forTotalXP: 36_000)?.title, "Elite")
        XCTAssertNil(FocusBadgeProgression.nextBadge(forTotalXP: 184_000))
        XCTAssertEqual(FocusBadgeProgression.xpToNext(totalXP: 36_000), 20_000)
        XCTAssertEqual(FocusBadgeProgression.progressFractionToNext(totalXP: 36_000), 0, accuracy: 0.001)
    }

    func testDidCrossThreshold() {
        let champion = FocusBadgeProgression.tiers.first { $0.title == "Champion" }!
        XCTAssertTrue(FocusBadgeProgression.didCrossThreshold(previousXP: 35_999, newXP: 36_000, badge: champion))
        XCTAssertFalse(FocusBadgeProgression.didCrossThreshold(previousXP: 36_000, newXP: 36_100, badge: champion))
    }
}
