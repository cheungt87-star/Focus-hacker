@testable import FocusHacker
import XCTest

final class PersonalWeeklyTargetFormattingTests: XCTestCase {
    func testSplit600Minutes() {
        let parts = PersonalWeeklyTargetFormatting.split(totalMinutes: 600)
        XCTAssertEqual(parts.hours, 10)
        XCTAssertEqual(parts.minutes, 0)
    }

    func testCompose10Hours() {
        XCTAssertEqual(PersonalWeeklyTargetFormatting.compose(hours: 10, minutes: 0), 600)
    }

    func testSnappedMinutesComponent() {
        XCTAssertEqual(PersonalWeeklyTargetFormatting.snappedMinutesComponent(0), 0)
        XCTAssertEqual(PersonalWeeklyTargetFormatting.snappedMinutesComponent(4), 0)
        XCTAssertEqual(PersonalWeeklyTargetFormatting.snappedMinutesComponent(20), 20)
        XCTAssertEqual(PersonalWeeklyTargetFormatting.snappedMinutesComponent(59), 55)
    }

    func testEditorBaselinePartsFromHackerGoal() {
        let parts = PersonalWeeklyTargetFormatting.editorBaselineParts()
        XCTAssertEqual(parts.hours, 13)
        XCTAssertEqual(parts.minutes, 20)
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.compose(hours: parts.hours, minutes: parts.minutes),
            ProfileDashboardMetrics.defaultWeeklyMinutesTarget
        )
    }

    func testIncrementMinutesWrapsAt55() {
        var hours = 2
        var minutes = 55
        PersonalWeeklyTargetFormatting.incrementMinutes(hours: &hours, minutes: &minutes)
        XCTAssertEqual(hours, 3)
        XCTAssertEqual(minutes, 0)
    }

    func testDecrementMinutesWrapsAtZero() {
        var hours = 3
        var minutes = 0
        PersonalWeeklyTargetFormatting.decrementMinutes(hours: &hours, minutes: &minutes)
        XCTAssertEqual(hours, 2)
        XCTAssertEqual(minutes, 55)
    }

    func testCannotIncrementPastMaximum() {
        XCTAssertFalse(
            PersonalWeeklyTargetFormatting.canIncrementHours(hours: 33, minutes: 20)
        )
        XCTAssertFalse(
            PersonalWeeklyTargetFormatting.canIncrementMinutes(hours: 33, minutes: 20)
        )
    }

    func testCannotDecrementPastMinimum() {
        XCTAssertFalse(
            PersonalWeeklyTargetFormatting.canDecrementHours(hours: 1, minutes: 40)
        )
        XCTAssertFalse(
            PersonalWeeklyTargetFormatting.canDecrementMinutes(hours: 1, minutes: 40)
        )
    }

    func testCanIncrementFromBelowMaximum() {
        XCTAssertTrue(
            PersonalWeeklyTargetFormatting.canIncrementMinutes(hours: 13, minutes: 15)
        )
    }

    func testClampRoundTripBelowMinimum() {
        let normalized = PersonalWeeklyTargetFormatting.normalizedParts(hours: 0, minutes: 30)
        XCTAssertEqual(normalized.totalMinutes, 100)
        XCTAssertEqual(normalized.hours, 1)
        XCTAssertEqual(normalized.minutes, 40)
    }

    func testComposeMaxWeeklyTarget() {
        XCTAssertEqual(PersonalWeeklyTargetFormatting.compose(hours: 33, minutes: 20), 2_000)
        let normalized = PersonalWeeklyTargetFormatting.normalizedParts(hours: 33, minutes: 20)
        XCTAssertEqual(normalized.totalMinutes, 2_000)
        XCTAssertEqual(normalized.hours, 33)
        XCTAssertEqual(normalized.minutes, 20)
    }

    func testSettingsAccessibilityLabel() {
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.settingsAccessibilityLabel(totalMinutes: 330),
            "330 minutes per week"
        )
    }

    func testHackerGoalComparisonAtBaseline() {
        let hackerGoal = ProfileDashboardMetrics.defaultWeeklyMinutesTarget
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.deltaVersusHackerGoalMinutes(
                personalMinutes: hackerGoal,
                hackerGoalMinutes: hackerGoal
            ),
            0
        )
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.percentVersusHackerGoal(
                personalMinutes: hackerGoal,
                hackerGoalMinutes: hackerGoal
            ),
            100
        )
        XCTAssertEqual(PersonalWeeklyTargetFormatting.deltaVersusHackerGoalDisplay(deltaMinutes: 0), "0 min")
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.percentVersusHackerGoalDisplay(percent: 100),
            "100% of hacker goal"
        )
    }

    func testHackerGoalComparisonDouble() {
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.deltaVersusHackerGoalMinutes(personalMinutes: 1_600),
            800
        )
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.percentVersusHackerGoal(personalMinutes: 1_600),
            200
        )
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.deltaVersusHackerGoalDisplay(deltaMinutes: 800),
            "+800 min"
        )
    }

    func testHackerGoalComparisonHalf() {
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.deltaVersusHackerGoalMinutes(personalMinutes: 400),
            -400
        )
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.percentVersusHackerGoal(personalMinutes: 400),
            50
        )
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.deltaVersusHackerGoalDisplay(deltaMinutes: -400),
            "-400 min"
        )
    }

    func testHackerGoalComparisonFivePercent() {
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.deltaVersusHackerGoalMinutes(personalMinutes: 40),
            -760
        )
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.percentVersusHackerGoal(personalMinutes: 40),
            5
        )
    }

    func testHackerGoalComparisonAccessibilityLabel() {
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.hackerGoalComparisonAccessibilityLabel(
                deltaMinutes: 200,
                percent: 125
            ),
            "200 minutes above hacker goal, 125 percent of hacker goal"
        )
        XCTAssertEqual(
            PersonalWeeklyTargetFormatting.hackerGoalComparisonAccessibilityLabel(
                deltaMinutes: -100,
                percent: 88
            ),
            "100 minutes below hacker goal, 88 percent of hacker goal"
        )
    }
}
