@testable import FocusHacker
import XCTest

final class ProfileHeroMetricsTests: XCTestCase {
    func testUnlockedLevelCountNewcomer() {
        XCTAssertEqual(ProfileHeroMetrics.unlockedLevelCount(totalXP: 0), 1)
        XCTAssertEqual(ProfileHeroMetrics.unlockedLevelCount(totalXP: 61), 1)
        XCTAssertEqual(ProfileHeroMetrics.unlockedLevelCount(totalXP: 999), 1)
    }

    func testUnlockedLevelCountRookie() {
        XCTAssertEqual(ProfileHeroMetrics.unlockedLevelCount(totalXP: 1_000), 2)
        XCTAssertEqual(ProfileHeroMetrics.unlockedLevelCount(totalXP: 2_999), 2)
    }

    func testUnlockedLevelCountMaxTier() {
        XCTAssertEqual(ProfileHeroMetrics.unlockedLevelCount(totalXP: 184_000), 10)
        XCTAssertEqual(ProfileHeroMetrics.unlockedLevelCount(totalXP: 500_000), 10)
    }

    func testNextBadgeXPDisplayWhileProgressing() {
        XCTAssertEqual(ProfileHeroMetrics.nextBadgeXPDisplay(totalXP: 61), 1_000)
        XCTAssertEqual(ProfileHeroMetrics.nextBadgeXPDisplay(totalXP: 1_000), 3_000)
    }

    func testNextBadgeXPDisplayAtMaxTier() {
        XCTAssertEqual(ProfileHeroMetrics.nextBadgeXPDisplay(totalXP: 184_000), 184_000)
        XCTAssertEqual(ProfileHeroMetrics.nextBadgeXPDisplay(totalXP: 500_000), 184_000)
    }

    func testTotalUnlockSegments() {
        XCTAssertEqual(ProfileHeroMetrics.totalUnlockSegments, 10)
    }

    func testProgressPercentDisplay() {
        XCTAssertEqual(ProfileHeroMetrics.progressPercentDisplay(fraction: 0.061), "6%")
        XCTAssertEqual(ProfileHeroMetrics.progressPercentDisplay(fraction: 1.0), "100%")
        XCTAssertEqual(ProfileHeroMetrics.progressPercentDisplay(fraction: 0), "0%")
        XCTAssertEqual(ProfileHeroMetrics.progressPercentDisplay(fraction: 1.5), "100%")
        XCTAssertEqual(ProfileHeroMetrics.progressPercentDisplay(fraction: -0.1), "0%")
    }

    func testXpProgressAmountNewcomer() {
        let fraction = FocusBadgeProgression.progressFractionToNext(totalXP: 61)
        XCTAssertEqual(
            ProfileHeroMetrics.xpProgressAmountText(totalXP: 61, tierRelativeFraction: fraction),
            "61 / 1,000 (6%)"
        )
    }

    func testXpProgressAmountMidTierCumulativeWithTierPercent() {
        let fraction = FocusBadgeProgression.progressFractionToNext(totalXP: 1_500)
        XCTAssertEqual(
            ProfileHeroMetrics.xpProgressAmountText(totalXP: 1_500, tierRelativeFraction: fraction),
            "1,500 / 3,000 (25%)"
        )
    }

    func testXpProgressMaxLevel() {
        XCTAssertTrue(ProfileHeroMetrics.isMaxBadge(totalXP: 184_000))
        XCTAssertEqual(ProfileHeroMetrics.xpProgressLabel(totalXP: 184_000), "Max level reached")
        XCTAssertEqual(
            ProfileHeroMetrics.xpProgressAmountText(totalXP: 184_000, tierRelativeFraction: 1),
            "184,000"
        )
    }

    func testXpProgressBarFractionClamp() {
        XCTAssertEqual(ProfileHeroMetrics.xpProgressBarFraction(fraction: 0), 0.02, accuracy: 0.001)
        XCTAssertEqual(ProfileHeroMetrics.xpProgressBarFraction(fraction: 0.061), 0.061, accuracy: 0.001)
        XCTAssertEqual(ProfileHeroMetrics.xpProgressBarFraction(fraction: 1.2), 1, accuracy: 0.001)
    }

    func testFormattedXPCommaSeparator() {
        XCTAssertEqual(ProfileHeroMetrics.formattedXP(999), "999")
        XCTAssertEqual(ProfileHeroMetrics.formattedXP(1_000), "1,000")
        XCTAssertEqual(ProfileHeroMetrics.formattedXP(12_500), "12,500")
    }

    func testLevelPositionLabel() {
        XCTAssertEqual(ProfileHeroMetrics.levelPositionLabel(badgeLevel: 0, unlockedCount: 1), "Level 1 · 1 / 10")
        XCTAssertEqual(ProfileHeroMetrics.levelPositionLabel(badgeLevel: 9, unlockedCount: 10), "Level 10 · 10 / 10")
    }
}
