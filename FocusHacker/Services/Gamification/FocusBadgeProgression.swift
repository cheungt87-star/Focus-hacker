import Foundation

struct FocusBadge: Sendable, Equatable {
    let level: Int
    let title: String
    let xpThreshold: Int
}

/// Lifetime XP badge tiers (GAMIFICATION_SPEC §5). Level never decreases.
enum FocusBadgeProgression {
    static let preTier = FocusBadge(level: 0, title: "Newcomer", xpThreshold: 0)

    static let tiers: [FocusBadge] = [
        FocusBadge(level: 1, title: "Rookie", xpThreshold: 1_000),
        FocusBadge(level: 2, title: "Amateur", xpThreshold: 3_000),
        FocusBadge(level: 3, title: "Semi-Pro", xpThreshold: 6_000),
        FocusBadge(level: 4, title: "Professional", xpThreshold: 12_000),
        FocusBadge(level: 5, title: "All-Star", xpThreshold: 22_000),
        FocusBadge(level: 6, title: "Champion", xpThreshold: 36_000),
        FocusBadge(level: 7, title: "Elite", xpThreshold: 56_000),
        FocusBadge(level: 8, title: "Hall of Famer", xpThreshold: 84_000),
        FocusBadge(level: 9, title: "Legend", xpThreshold: 124_000),
        FocusBadge(level: 10, title: "GOAT", xpThreshold: 184_000)
    ]

    static func displayName(for level: Int) -> String {
        badge(forLevel: level)?.title ?? tiers.first!.title
    }

    static func badge(forLevel level: Int) -> FocusBadge? {
        tiers.first { $0.level == level }
    }

    /// Highest badge whose threshold the user has reached (at least Rookie).
    static func badge(forTotalXP totalXP: Int) -> FocusBadge {
        let xp = max(0, totalXP)
        return tiers.last { xp >= $0.xpThreshold } ?? preTier
    }

    /// Next badge above current tier, if any.
    static func nextBadge(forTotalXP totalXP: Int) -> FocusBadge? {
        let xp = max(0, totalXP)
        return tiers.first { xp < $0.xpThreshold }
    }

    /// Progress from current badge threshold toward next (1.0 at max tier).
    static func progressFractionToNext(totalXP: Int) -> Double {
        let xp = max(0, totalXP)
        let current = badge(forTotalXP: xp)
        guard let next = nextBadge(forTotalXP: xp) else { return 1 }
        let span = next.xpThreshold - current.xpThreshold
        guard span > 0 else { return 1 }
        return min(1, max(0, Double(xp - current.xpThreshold) / Double(span)))
    }

    static func xpToNext(totalXP: Int) -> Int {
        let xp = max(0, totalXP)
        guard let next = nextBadge(forTotalXP: xp) else { return 0 }
        return max(0, next.xpThreshold - xp)
    }

    /// True when `totalXP` crosses `badge.xpThreshold` from strictly below.
    static func didCrossThreshold(previousXP: Int, newXP: Int, badge: FocusBadge) -> Bool {
        previousXP < badge.xpThreshold && newXP >= badge.xpThreshold
    }
}
