import Foundation

enum ProfileWeeklyProgressMockData {
    struct GoalSnapshot: Sendable {
        let fraction: Double
        let percentDisplay: Int
        let currentMinutes: Int
        let targetMinutes: Int
    }

    static let hacker = GoalSnapshot(
        fraction: 0.32,
        percentDisplay: 32,
        currentMinutes: 256,
        targetMinutes: 800
    )

    static let personal = GoalSnapshot(
        fraction: 0.86,
        percentDisplay: 86,
        currentMinutes: 516,
        targetMinutes: 600
    )
}
