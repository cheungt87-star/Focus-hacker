@testable import FocusHacker
import XCTest

final class MenuBarGetReadyCountdownTests: XCTestCase {
    func testTickSequenceCountsDownToZero() {
        XCTAssertEqual(MenuBarGetReadyCountdown.tickSequence(), [10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    }

    func testMenuBarPillTextUsesGetReadyLabel() {
        XCTAssertEqual(MenuBarGetReadyCountdown.menuBarPillText(secondsRemaining: 10), "GET READY: 10")
        XCTAssertEqual(MenuBarGetReadyCountdown.menuBarPillText(secondsRemaining: 0), "GET READY: 0")
        XCTAssertEqual(MenuBarGetReadyCountdown.menuBarPillText(secondsRemaining: -3), "GET READY: 0")
    }

    func testAccessibilityLabel() {
        XCTAssertEqual(
            MenuBarGetReadyCountdown.menuBarAccessibilityLabel(secondsRemaining: 4),
            "Get Ready, 4 seconds remaining"
        )
    }

    func testLabelIsNotTimeToWork() {
        XCTAssertEqual(MenuBarGetReadyCountdown.label, "Get Ready")
        XCTAssertFalse(MenuBarGetReadyCountdown.label.localizedCaseInsensitiveContains("time to work"))
    }

    func testShouldPlayTickForTenThroughOneOnly() {
        let playableTicks = MenuBarGetReadyCountdown.tickSequence().filter {
            MenuBarGetReadyCountdown.shouldPlayTick(forSecondsRemaining: $0)
        }
        XCTAssertEqual(playableTicks, [10, 9, 8, 7, 6, 5, 4, 3, 2, 1])
        XCTAssertFalse(MenuBarGetReadyCountdown.shouldPlayTick(forSecondsRemaining: 0))
    }
}
