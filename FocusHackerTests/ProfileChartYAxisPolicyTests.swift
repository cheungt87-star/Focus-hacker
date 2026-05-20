@testable import FocusHacker
import XCTest

final class ProfileChartYAxisPolicyTests: XCTestCase {
    func testDailyMinutesFromWeekly800() {
        XCTAssertEqual(ProfileChartTargets.dailyMinutes(fromWeekly: 800), 114)
    }

    func testDailyMinutesFromWeekly600() {
        XCTAssertEqual(ProfileChartTargets.dailyMinutes(fromWeekly: 600), 86)
    }

    func testMockFocusHackerAndPersonalDailyTargets() {
        XCTAssertEqual(ProfileChartTargets.mockFocusHackerDailyMinutes, 114)
        XCTAssertEqual(ProfileChartTargets.mockPersonalDailyMinutes, 86)
    }

    func testWeekYAxisUses30MinuteSteps() {
        let policy = ProfileChartYAxisPolicyBuilder.make(
            period: .week,
            dataMaxMinutes: 90,
            targetMinutes: [114, 86]
        )

        XCTAssertEqual(policy.tickValuesMinutes.first, 0)
        XCTAssertEqual(policy.tickValuesMinutes[1], 30)
        XCTAssertFalse(policy.usesHourLabels)
        XCTAssertGreaterThanOrEqual(policy.domainMaxMinutes, 114)
    }

    func testDomainIncludesTargetLines() {
        let policy = ProfileChartYAxisPolicyBuilder.make(
            period: .month,
            dataMaxMinutes: 30,
            targetMinutes: [114, 86]
        )

        XCTAssertGreaterThanOrEqual(policy.domainMaxMinutes, 114)
        XCTAssertTrue(policy.usesHourLabels)
        XCTAssertEqual(policy.formatLabel(minutes: 120), "2h")
    }

    func testMonthYAxisUses60MinuteSteps() {
        let policy = ProfileChartYAxisPolicyBuilder.make(
            period: .month,
            dataMaxMinutes: 180,
            targetMinutes: [114, 86]
        )

        XCTAssertEqual(policy.tickValuesMinutes[1], 60)
        XCTAssertEqual(policy.formatLabel(minutes: 60), "1h")
    }

    func testYearYAxisUses120MinuteSteps() {
        let policy = ProfileChartYAxisPolicyBuilder.make(
            period: .year,
            dataMaxMinutes: 200,
            targetMinutes: [114, 86]
        )

        XCTAssertEqual(policy.tickValuesMinutes[1], 120)
        XCTAssertEqual(policy.formatLabel(minutes: 240), "4h")
    }
}
