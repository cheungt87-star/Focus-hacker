import XCTest
@testable import FocusHacker

final class ProfileDashboardMetricsTests: XCTestCase {
    func testProfileHandleSlugifiesDisplayName() {
        XCTAssertEqual(
            ProfileDashboardMetrics.profileHandle(from: "Alex Chen"),
            "@alexchen"
        )
    }

    func testProfileHandleEmptyFallsBackToUser() {
        XCTAssertEqual(
            ProfileDashboardMetrics.profileHandle(from: "   "),
            "@user"
        )
    }

    func testWeeklyMinutesProgressClamped() {
        XCTAssertEqual(
            ProfileDashboardMetrics.weeklyMinutesProgressFraction(currentMinutes: 450),
            450.0 / 800.0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ProfileDashboardMetrics.weeklyMinutesProgressFraction(currentMinutes: 1200),
            1.0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ProfileDashboardMetrics.weeklyMinutesRemaining(currentMinutes: 450),
            350
        )
    }

    func testWeeklyMinutesPercentDisplay() {
        XCTAssertEqual(
            ProfileDashboardMetrics.weeklyMinutesPercentDisplay(currentMinutes: 400),
            50
        )
    }

    func testWeeklyProgressFractionsForHackerAndPersonalTargets() {
        let currentMinutes = 450

        XCTAssertEqual(
            ProfileDashboardMetrics.weeklyMinutesProgressFraction(
                currentMinutes: currentMinutes,
                targetMinutes: 800
            ),
            450.0 / 800.0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ProfileDashboardMetrics.weeklyMinutesProgressFraction(
                currentMinutes: currentMinutes,
                targetMinutes: 600
            ),
            0.75,
            accuracy: 0.001
        )
    }

    func testWeeklyProgressClampedAtZeroAndAboveTarget() {
        XCTAssertEqual(
            ProfileDashboardMetrics.weeklyMinutesProgressFraction(
                currentMinutes: 0,
                targetMinutes: 800
            ),
            0.0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ProfileDashboardMetrics.weeklyMinutesProgressFraction(
                currentMinutes: 1200,
                targetMinutes: 600
            ),
            1.0,
            accuracy: 0.001
        )
    }
}
