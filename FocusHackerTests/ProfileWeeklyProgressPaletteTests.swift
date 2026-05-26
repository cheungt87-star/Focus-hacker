@testable import FocusHacker
import AppKit
import SwiftUI
import XCTest

final class ProfileWeeklyProgressPaletteTests: XCTestCase {
    func testWeeklyPercentMatchesSpecExample() {
        XCTAssertEqual(
            ProfileDashboardMetrics.weeklyMinutesPercentDisplay(
                currentMinutes: 49,
                targetMinutes: 800
            ),
            6
        )
        XCTAssertEqual(
            ProfileDashboardMetrics.weeklyMinutesPercentDisplay(
                currentMinutes: 49,
                targetMinutes: 330
            ),
            15
        )
    }

    func testGoalFormattingHelpers() {
        XCTAssertEqual(ProfileWeeklyProgressFormatting.focusMinutesValueText(minutes: 51), "51")
        XCTAssertEqual(ProfileWeeklyProgressFormatting.goalMinutesToGoText(remainingMinutes: 749), "749 min to go")
        XCTAssertEqual(ProfileWeeklyProgressFormatting.goalPercentText(percentDisplay: 6), "6%")
    }

    func testStreakFormattingHelpers() {
        XCTAssertEqual(ProfileWeeklyProgressFormatting.streakWeeksDisplay(4), "4")
        XCTAssertEqual(ProfileWeeklyProgressFormatting.streakUnitLabel(weeks: 1), "week")
        XCTAssertEqual(ProfileWeeklyProgressFormatting.streakUnitLabel(weeks: 0), "weeks")
        XCTAssertEqual(
            ProfileWeeklyProgressFormatting.streakExplainer,
            "Weeks in a row hitting your goals"
        )
        XCTAssertEqual(
            ProfileWeeklyProgressFormatting.streakAccessibilityLabel(weeks: 3),
            "Week streak, 3 weeks. Weeks in a row hitting your goals"
        )
    }

    func testGoalProgressBarFractionUsesTwoPercentMinimum() {
        XCTAssertEqual(
            ProfileWeeklyProgressFormatting.goalProgressBarFraction(fraction: 0),
            0.02,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ProfileWeeklyProgressFormatting.goalProgressBarFraction(fraction: 0.15),
            0.15,
            accuracy: 0.001
        )
    }

    func testPaletteCardBackgroundDiffersBetweenLightAndDark() {
        let light = ProfileWeeklyProgressPalette.resolve(for: .light)
        let dark = ProfileWeeklyProgressPalette.resolve(for: .dark)

        XCTAssertNotEqual(colorHex(light.cardBackground), colorHex(dark.cardBackground))
        XCTAssertEqual(colorHex(light.cardBackground), 0xFFFFFF)
        XCTAssertEqual(colorHex(dark.cardBackground), 0x2C2C2E)
    }

    func testPaletteAccentColors() {
        let light = ProfileWeeklyProgressPalette.resolve(for: .light)

        XCTAssertEqual(colorHex(light.hackerAccent), 0x2563EB)
        XCTAssertEqual(colorHex(light.streakFill), 0xFBBF24)
        XCTAssertEqual(colorHex(light.streakBorder), 0xF59E0B)
        XCTAssertEqual(colorHex(light.personalAccent), 0xE9D5FF)
        XCTAssertEqual(colorHex(light.streakSidebarBackground), 0xF9FAFB)

        let dark = ProfileWeeklyProgressPalette.resolve(for: .dark)
        XCTAssertEqual(colorHex(dark.hackerAccent), 0x2563EB)
        XCTAssertEqual(colorHex(dark.streakFill), 0xFBBF24)
        XCTAssertEqual(colorHex(dark.personalAccent), 0xE9D5FF)
    }

    private func colorHex(_ color: Color) -> UInt32 {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let r = UInt32(round(red * 255))
        let g = UInt32(round(green * 255))
        let b = UInt32(round(blue * 255))
        return (r << 16) | (g << 8) | b
    }
}
