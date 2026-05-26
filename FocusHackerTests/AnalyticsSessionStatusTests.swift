import XCTest
@testable import FocusHacker

final class AnalyticsSessionStatusTests: XCTestCase {
    func testNaturallyConcludedWhenFlagTrue() {
        XCTAssertTrue(
            AnalyticsSessionStatusResolver.isNaturallyConcluded(naturallyConcluded: true, didComplete: false)
        )
    }

    func testNotNaturallyConcludedWhenFlagFalse() {
        XCTAssertFalse(
            AnalyticsSessionStatusResolver.isNaturallyConcluded(naturallyConcluded: false, didComplete: true)
        )
    }

    func testLegacyFallbackUsesDidComplete() {
        XCTAssertTrue(
            AnalyticsSessionStatusResolver.isNaturallyConcluded(naturallyConcluded: nil, didComplete: true)
        )
        XCTAssertFalse(
            AnalyticsSessionStatusResolver.isNaturallyConcluded(naturallyConcluded: nil, didComplete: false)
        )
    }

    func testRecordStatusMapping() {
        let complete = AnalyticsSessionRecord(
            id: "1",
            endedAt: Date(),
            startedAt: nil,
            focusMinutes: 10,
            xpAwarded: 15,
            isNaturallyConcluded: true
        )
        let abandoned = AnalyticsSessionRecord(
            id: "2",
            endedAt: Date(),
            startedAt: nil,
            focusMinutes: 10,
            xpAwarded: 10,
            isNaturallyConcluded: false
        )
        XCTAssertEqual(complete.status, .complete)
        XCTAssertEqual(abandoned.status, .abandoned)
    }
}
