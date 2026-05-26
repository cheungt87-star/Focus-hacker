import Foundation

/// XP from completed focus minutes per GAMIFICATION_SPEC §4.1.
enum FocusXPCalculator {
    static let baseXPPerMinute = 1
    static let naturalCompletionMultiplier = 1.5

    /// `minutes × 1 × (1.5 if naturally concluded, else 1.0)`, rounded half-up.
    static func xp(forFocusMinutes minutes: Int, naturallyConcluded: Bool) -> Int {
        let clamped = max(0, minutes)
        guard clamped > 0 else { return 0 }
        let multiplier = naturallyConcluded ? naturalCompletionMultiplier : 1.0
        let raw = Double(clamped) * Double(baseXPPerMinute) * multiplier
        return Int(raw.rounded())
    }
}
