import XCTest
@testable import FocusHacker

final class AnalyticsSessionSorterTests: XCTestCase {
    private func record(
        id: String,
        endedAt: Date,
        focusMinutes: Int = 0,
        xp: Int = 0
    ) -> AnalyticsSessionRecord {
        AnalyticsSessionRecord(
            id: id,
            endedAt: endedAt,
            startedAt: nil,
            focusMinutes: focusMinutes,
            xpAwarded: xp,
            isNaturallyConcluded: true
        )
    }

    func testSortByDateNewestFirst() {
        let d1 = Date(timeIntervalSince1970: 100)
        let d2 = Date(timeIntervalSince1970: 200)
        let d3 = Date(timeIntervalSince1970: 300)
        let sorted = AnalyticsSessionSorter.sorted(
            [record(id: "a", endedAt: d1), record(id: "b", endedAt: d3), record(id: "c", endedAt: d2)],
            sortKey: .date,
            ascending: false
        )
        XCTAssertEqual(sorted.map(\.id), ["b", "c", "a"])
    }

    func testSortByFocusTimeHighestFirst() {
        let base = Date()
        let sorted = AnalyticsSessionSorter.sorted(
            [
                record(id: "a", endedAt: base, focusMinutes: 10),
                record(id: "b", endedAt: base.addingTimeInterval(1), focusMinutes: 50),
                record(id: "c", endedAt: base.addingTimeInterval(2), focusMinutes: 30),
            ],
            sortKey: .focusTime,
            ascending: false
        )
        XCTAssertEqual(sorted.map(\.id), ["b", "c", "a"])
    }

    func testSortByXPLowestFirst() {
        let base = Date()
        let sorted = AnalyticsSessionSorter.sorted(
            [
                record(id: "a", endedAt: base, xp: 100),
                record(id: "b", endedAt: base.addingTimeInterval(1), xp: 0),
                record(id: "c", endedAt: base.addingTimeInterval(2), xp: 50),
            ],
            sortKey: .xp,
            ascending: true
        )
        XCTAssertEqual(sorted.map(\.id), ["b", "c", "a"])
    }
}
