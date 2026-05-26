import Foundation

enum AnalyticsSessionSorter {
    static func sorted(
        _ records: [AnalyticsSessionRecord],
        sortKey: AnalyticsSessionSortKey,
        ascending: Bool
    ) -> [AnalyticsSessionRecord] {
        let ordered = records.sorted { lhs, rhs in
            let comparison: Bool
            switch sortKey {
            case .date:
                comparison = lhs.endedAt < rhs.endedAt
            case .focusTime:
                if lhs.focusMinutes != rhs.focusMinutes {
                    comparison = lhs.focusMinutes < rhs.focusMinutes
                } else {
                    comparison = lhs.endedAt < rhs.endedAt
                }
            case .xp:
                if lhs.xpAwarded != rhs.xpAwarded {
                    comparison = lhs.xpAwarded < rhs.xpAwarded
                } else {
                    comparison = lhs.endedAt < rhs.endedAt
                }
            }
            return ascending ? comparison : !comparison
        }
        return ordered
    }
}
