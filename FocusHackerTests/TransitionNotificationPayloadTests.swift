import XCTest
@testable import FocusHacker

final class TransitionNotificationPayloadTests: XCTestCase {
    func testCompletionPayload_focusTimeAndXP() {
        let payload = TransitionNotificationService.completionPayload(
            xpAwarded: 17,
            focusMinutes: 100,
            focusSeconds: 6000
        )

        XCTAssertEqual(payload.title, "Session complete — nice work 🎉")
        XCTAssertEqual(payload.body, "Focus time: 1h 40m +17xp")
    }

    func testCompletionPayload_shortSession() {
        let payload = TransitionNotificationService.completionPayload(
            xpAwarded: 50,
            focusMinutes: 25,
            focusSeconds: 1500
        )

        XCTAssertEqual(payload.body, "Focus time: 25m +50xp")
    }

    func testCompletionPayload_zeroFocusAndXP() {
        let payload = TransitionNotificationService.completionPayload(
            xpAwarded: 0,
            focusMinutes: 0,
            focusSeconds: 0
        )

        XCTAssertEqual(payload.body, "Focus time: 0h +0xp")
    }

    func testCompletionPayload_derivesMinutesFromSecondsWhenMinutesZero() {
        let payload = TransitionNotificationService.completionPayload(
            xpAwarded: 0,
            focusMinutes: 0,
            focusSeconds: 90
        )

        XCTAssertEqual(payload.body, "Focus time: 2m +0xp")
    }

    func testDisplayFocusMinutes_usesCeilingFromSeconds() {
        XCTAssertEqual(
            TransitionNotificationService.displayFocusMinutes(focusMinutes: 0, focusSeconds: 90),
            2
        )
        XCTAssertEqual(
            TransitionNotificationService.displayFocusMinutes(focusMinutes: 25, focusSeconds: 100),
            25
        )
    }
}
