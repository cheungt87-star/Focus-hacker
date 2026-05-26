import Foundation

/// Pre-focus countdown shown in the menu bar when starting from the popover.
enum MenuBarGetReadyCountdown {
    static let preDisplayDelayNanoseconds: UInt64 = 500_000_000
    static let totalSeconds = 10
    static let label = "Get Ready"

    static func menuBarPillText(secondsRemaining: Int) -> String {
        "GET READY: \(max(0, secondsRemaining))"
    }

    static func menuBarAccessibilityLabel(secondsRemaining: Int) -> String {
        "\(label), \(max(0, secondsRemaining)) seconds remaining"
    }

    /// Tick sequence after the pill first appears: 10, 9, …, 0 (inclusive).
    static func tickSequence() -> [Int] {
        Array(stride(from: totalSeconds, through: 0, by: -1))
    }

    /// Whether a countdown second should play an audible tick (10…1 only, not 0).
    static func shouldPlayTick(forSecondsRemaining secondsRemaining: Int) -> Bool {
        secondsRemaining > 0
    }
}
