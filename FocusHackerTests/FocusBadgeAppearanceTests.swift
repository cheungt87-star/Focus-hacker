@testable import FocusHacker
import XCTest

final class FocusBadgeAppearanceTests: XCTestCase {
    func testNewcomerSpecGradient() {
        let appearance = FocusBadgeAppearance.forLevel(0)
        XCTAssertEqual(appearance.level, 0)
        XCTAssertNil(appearance.subtitle)
        XCTAssertEqual(appearance.gradientStopHexes.first, 0x25A876)
        XCTAssertEqual(appearance.accentHex, 0x1DB97C)
        XCTAssertEqual(appearance.emblemSymbol, "sparkles")
    }

    func testProfileCardTokensPresent() {
        let appearance = FocusBadgeAppearance.forLevel(5)
        XCTAssertEqual(appearance.accentHex, 0xFFD700)
        XCTAssertEqual(appearance.pillTextHex, 0xDAA520)
        XCTAssertEqual(appearance.iconColorOpacity, 1, accuracy: 0.001)
    }

    func testUnknownLevelFallsBackToNewcomer() {
        let appearance = FocusBadgeAppearance.forLevel(99)
        XCTAssertEqual(appearance.level, 0)
    }

    func testTierSubtitles() {
        XCTAssertNil(FocusBadgeAppearance.forLevel(1).subtitle)
        XCTAssertNil(FocusBadgeAppearance.forLevel(2).subtitle)
        XCTAssertEqual(FocusBadgeAppearance.forLevel(3).subtitle, "Bronze")
        XCTAssertEqual(FocusBadgeAppearance.forLevel(4).subtitle, "Silver")
        XCTAssertEqual(FocusBadgeAppearance.forLevel(5).subtitle, "Gold")
        XCTAssertEqual(FocusBadgeAppearance.forLevel(6).subtitle, "Platinum")
        XCTAssertEqual(FocusBadgeAppearance.forLevel(7).subtitle, "Sapphire")
        XCTAssertEqual(FocusBadgeAppearance.forLevel(8).subtitle, "Emerald")
        XCTAssertEqual(FocusBadgeAppearance.forLevel(9).subtitle, "Ruby")
        XCTAssertEqual(FocusBadgeAppearance.forLevel(10).subtitle, "Black Diamond")
    }

    func testSemiProBronzeGradientStart() {
        XCTAssertEqual(FocusBadgeAppearance.forLevel(3).gradientStopHexes.first, 0xDD6F1F)
    }

    func testGOATBlackDiamondBorder() {
        let appearance = FocusBadgeAppearance.forLevel(10)
        XCTAssertEqual(appearance.borderHex, 0xFACC15)
        XCTAssertEqual(appearance.subtitle, "Black Diamond")
    }

    func testForBadgeChampionAt36kXP() {
        let badge = FocusBadgeProgression.badge(forTotalXP: 36_000)
        XCTAssertEqual(badge.title, "Champion")
        let appearance = FocusBadgeAppearance.forBadge(badge)
        XCTAssertEqual(appearance.level, 6)
        XCTAssertEqual(appearance.subtitle, "Platinum")
    }

    func testForTotalXP() {
        XCTAssertEqual(FocusBadgeAppearance.forTotalXP(500).level, 0)
        XCTAssertEqual(FocusBadgeAppearance.forTotalXP(1_000).level, 1)
        XCTAssertEqual(FocusBadgeAppearance.forTotalXP(200_000).level, 10)
    }

    func testAllTierLevelsHaveAppearances() {
        for tier in FocusBadgeProgression.tiers {
            XCTAssertEqual(FocusBadgeAppearance.forBadge(tier).level, tier.level)
        }
    }

    func testBadgePanelGradientUsesThreeStops() {
        let appearance = FocusBadgeAppearance.forLevel(0)
        XCTAssertEqual(appearance.gradientStopHexes.count, 3)
        XCTAssertEqual(FocusBadgeAppearance.badgePanelGradientOpacity, 0.25, accuracy: 0.001)
        XCTAssertEqual(FocusBadgeAppearance.badgePanelDividerOpacity, 0.35, accuracy: 0.001)
    }

    func testBadgePanelGradientCustomOpacity() {
        let appearance = FocusBadgeAppearance.forLevel(1)
        _ = appearance.badgePanelGradient(opacity: 0.5)
        XCTAssertEqual(appearance.gradientStopHexes.count, 3)
    }
}
