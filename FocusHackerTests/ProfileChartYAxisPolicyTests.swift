@testable import FocusHacker
import XCTest

final class ProfileChartYAxisPolicyTests: XCTestCase {
    func testDailyMinutesFromWeekly800() {
        XCTAssertEqual(ProfileChartTargets.dailyMinutes(fromWeekly: 800), 114)
    }

    func testDailyMinutesFromWeekly600() {
        XCTAssertEqual(ProfileChartTargets.dailyMinutes(fromWeekly: 600), 86)
    }

    func testFixedDomainIsFourHours() {
        XCTAssertEqual(ProfileChartYAxisPolicy.defaultDomainMaxMinutes, 240)
        XCTAssertEqual(ProfileChartYAxisPolicy.defaultTickStepMinutes, 60)
    }

    func testWeekAndMonthUseOneHourTicks() {
        for period in [ProfileChartPeriod.week, ProfileChartPeriod.month] {
            let policy = ProfileChartYAxisPolicyBuilder.make(
                period: period,
                dataMaxMinutes: 300,
                targetMinutes: [114, 86]
            )
            XCTAssertEqual(policy.domainMaxMinutes, 240)
            XCTAssertEqual(policy.tickValuesMinutes, [0, 60, 120, 180, 240])
        }
    }

    func testYearScalesDomainAboveFourHours() {
        let policy = ProfileChartYAxisPolicyBuilder.make(
            period: .year,
            dataMaxMinutes: 3_100,
            targetMinutes: [114, 86]
        )

        XCTAssertEqual(policy.domainMaxMinutes, 3_600)
        XCTAssertEqual(policy.tickValuesMinutes, [0, 600, 1_200, 1_800, 2_400, 3_000, 3_600])
    }

    func testYearUsesMinimumDomainWhenDataIsLow() {
        let policy = ProfileChartYAxisPolicyBuilder.make(
            period: .year,
            dataMaxMinutes: 120,
            targetMinutes: [114, 86]
        )

        XCTAssertEqual(policy.domainMaxMinutes, 600)
        XCTAssertEqual(policy.tickValuesMinutes, [0, 600])
    }

    func testDomainIgnoresHighDataAndTargetsForWeek() {
        let policy = ProfileChartYAxisPolicyBuilder.make(
            period: .week,
            dataMaxMinutes: 500,
            targetMinutes: [200, 180]
        )

        XCTAssertEqual(policy.tickValuesMinutes.last, 240)
        XCTAssertEqual(policy.formatLabel(minutes: 0), "0h")
        XCTAssertEqual(policy.formatLabel(minutes: 60), "1h")
        XCTAssertEqual(policy.formatLabel(minutes: 240), "4h")
    }
}
