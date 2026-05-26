import XCTest
@testable import FocusHacker

final class AnalyticsSessionFormattingTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = calendar.timeZone
        return calendar.date(from: components)!
    }

    func testTableDateLabelFormat() {
        let label = AnalyticsSessionFormatting.tableDateLabel(
            for: date(2026, 5, 25, hour: 9),
            calendar: calendar
        )
        XCTAssertEqual(label, "MON 25/05/26")
    }

    func testTableTimeLabelFormat() {
        let label = AnalyticsSessionFormatting.tableTimeLabel(
            for: date(2026, 5, 25, hour: 9, minute: 5),
            calendar: calendar
        )
        XCTAssertEqual(label, "09:05")
    }

    func testFocusDurationFormatting() {
        XCTAssertEqual(AnalyticsSessionFormatting.focusDuration(minutes: 0), "0h")
        XCTAssertEqual(AnalyticsSessionFormatting.focusDuration(minutes: 50), "50m")
        XCTAssertEqual(AnalyticsSessionFormatting.focusDuration(minutes: 95), "1h 35m")
        XCTAssertEqual(AnalyticsSessionFormatting.focusDuration(minutes: 120), "2h")
    }
}
