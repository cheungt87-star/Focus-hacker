import Foundation
import SwiftUI

@available(macOS 14.0, *)
@MainActor
final class AnalyticsDetailViewModel: ObservableObject {
    @Published private(set) var monthStart: Date
    @Published var sortKey: AnalyticsSessionSortKey = .date
    @Published var sortAscending = false
    @Published private(set) var selectedSessionID: String?
    @Published private(set) var allRecords: [AnalyticsSessionRecord] = []
    @Published private(set) var monthSummary = AnalyticsMonthSummary(
        sessionCount: 0,
        totalFocusMinutes: 0,
        totalXP: 0,
        completionCount: 0,
        monthSubtitle: ""
    )
    @Published private(set) var displayedSessions: [AnalyticsSessionRecord] = []
    @Published private(set) var isLoading = true

    private let analyticsSessionReader: AnalyticsSessionReading
    private let calendar: Calendar

    init(
        analyticsSessionReader: AnalyticsSessionReading,
        calendar: Calendar = .current,
        monthStart: Date? = nil
    ) {
        self.analyticsSessionReader = analyticsSessionReader
        self.calendar = calendar
        self.monthStart = monthStart ?? ProfileChartNavigation.currentMonthStart(calendar: calendar)
        refreshDerivedState()
    }

    var monthRangeTitle: String {
        ProfileChartNavigation.monthRangeTitle(monthStart: monthStart, calendar: calendar)
    }

    var canNavigateMonthForward: Bool {
        monthStart < ProfileChartNavigation.currentMonthStart(calendar: calendar)
    }

    var isHighestFirst: Bool { !sortAscending }

    func loadSessions() async {
        // #region agent log
        let loadStart = CFAbsoluteTimeGetCurrent()
        DebugSessionLog82afba.write(
            hypothesisId: "H1",
            location: "AnalyticsDetailViewModel.loadSessions",
            message: "load_started"
        )
        // #endregion
        isLoading = true
        defer { isLoading = false }
        do {
            allRecords = try await analyticsSessionReader.fetchEndedSessions()
        } catch {
            allRecords = []
        }
        refreshDerivedState()
        // #region agent log
        let loadMs = Int((CFAbsoluteTimeGetCurrent() - loadStart) * 1000)
        DebugSessionLog82afba.write(
            hypothesisId: "H1",
            location: "AnalyticsDetailViewModel.loadSessions",
            message: "load_finished",
            data: [
                "durationMs": "\(loadMs)",
                "recordCount": "\(allRecords.count)",
            ]
        )
        // #endregion
    }

    func navigateMonthPrevious() {
        guard let previous = ProfileChartNavigation.previousMonthStart(from: monthStart, calendar: calendar) else {
            return
        }
        monthStart = previous
        selectedSessionID = nil
        refreshDerivedState()
    }

    func navigateMonthNext() {
        guard canNavigateMonthForward,
              let next = ProfileChartNavigation.nextMonthStart(from: monthStart, calendar: calendar)
        else {
            return
        }
        monthStart = next
        selectedSessionID = nil
        refreshDerivedState()
    }

    func selectSort(_ key: AnalyticsSessionSortKey) {
        if sortKey == key {
            return
        }
        sortKey = key
        sortAscending = defaultAscending(for: key)
        refreshDerivedState()
    }

    func selectSortDirection(highestFirst: Bool) {
        let ascending = !highestFirst
        guard sortAscending != ascending else { return }
        sortAscending = ascending
        refreshDerivedState()
    }

    func toggleRowSelection(id: String) {
        if selectedSessionID == id {
            selectedSessionID = nil
        } else {
            selectedSessionID = id
        }
    }

    private func defaultAscending(for key: AnalyticsSessionSortKey) -> Bool {
        switch key {
        case .date:
            return false
        case .focusTime, .xp:
            return false
        }
    }

    private func refreshDerivedState() {
        let monthRecords = AnalyticsMonthFilter.sessions(
            inMonthStarting: monthStart,
            from: allRecords,
            calendar: calendar
        )
        monthSummary = AnalyticsMonthAggregator.summary(
            from: monthRecords,
            monthStart: monthStart,
            calendar: calendar
        )
        displayedSessions = AnalyticsSessionSorter.sorted(
            monthRecords,
            sortKey: sortKey,
            ascending: sortAscending
        )
    }
}
