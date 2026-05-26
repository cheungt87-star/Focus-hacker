import Foundation

/// When a focus session counts as "naturally concluded" for the 1.5× XP multiplier (GAMIFICATION_SPEC §3.3).
enum NaturalCompletionPolicy {
    /// Full session finished via timer completion path (`TimerService.completeSession()`).
    static let naturallyConcludedOnFullCompletion = true

    /// User ended early (`TimerService.endSession()`); partial minutes still earn 1× XP.
    static let naturallyConcludedOnEarlyEnd = false
}
