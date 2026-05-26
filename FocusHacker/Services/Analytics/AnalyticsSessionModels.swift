import Foundation

enum AnalyticsSessionSortKey: String, CaseIterable, Sendable {
    case date
    case focusTime
    case xp
}

enum AnalyticsSessionStatus: Sendable, Equatable {
    case complete
    case abandoned
}

struct AnalyticsSessionRecord: Identifiable, Sendable, Equatable {
    let id: String
    let endedAt: Date
    let startedAt: Date?
    let focusMinutes: Int
    let xpAwarded: Int
    let isNaturallyConcluded: Bool

    var status: AnalyticsSessionStatus {
        isNaturallyConcluded ? .complete : .abandoned
    }
}

struct AnalyticsMonthSummary: Sendable, Equatable {
    let sessionCount: Int
    let totalFocusMinutes: Int
    let totalXP: Int
    let completionCount: Int
    let monthSubtitle: String

    var completionRatePercent: Int {
        guard sessionCount > 0 else { return 0 }
        return Int((Double(completionCount) / Double(sessionCount) * 100).rounded())
    }

    var completionSubLabel: String {
        "\(completionCount) of \(sessionCount) finished"
    }
}

enum AnalyticsSessionStatusResolver {
    static func isNaturallyConcluded(
        naturallyConcluded: Bool?,
        didComplete: Bool?
    ) -> Bool {
        if let natural = naturallyConcluded {
            return natural
        }
        return didComplete == true
    }
}
